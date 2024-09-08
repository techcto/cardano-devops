Instance = search("aws_opsworks_instance").first

CardanoPath = node[:install][:CardanoPath]
DatabasePath = node[:install][:DatabasePath]
PublicNodeAddress = node[:install][:PublicNodeAddress]
RelayNodePort = node[:install][:RelayNodePort]
BlockNodeAddress = Instance["private_ip"]
BlockNodePort = node[:install][:BlockNodePort]
Network = node[:install][:Network]
BackupBucket = node[:install][:BackupBucket]

ProjectName = node[:install][:ProjectName]
ProjectDescription = node[:install][:ProjectDescription]
ProjectTicker = node[:install][:ProjectTicker]
ProjectHomepage = node[:install][:ProjectHomepage]

script "config_block" do
	interpreter "bash"
	user "root"
	cwd "/root"
	code <<-EOH
		mkdir -p #{CardanoPath}/config/#{Network}
		cd #{CardanoPath}/config/#{Network}
		wget https://hydra.iohk.io/build/7370192/download/1/#{Network}-config.json
		sed -i #{Network}-config.json -e "s|TraceBlockFetchDecisions\": false|TraceBlockFetchDecisions\": true|g" -e "s|127.0.0.1|0.0.0.0|g"
		wget https://hydra.iohk.io/build/7370192/download/1/#{Network}-byron-genesis.json
		wget https://hydra.iohk.io/build/7370192/download/1/#{Network}-shelley-genesis.json
		wget https://hydra.iohk.io/build/7370192/download/1/#{Network}-alonzo-genesis.json
		wget https://hydra.iohk.io/build/7370192/download/1/#{Network}-db-sync-config.json
		
		# Init Block Producer
		wget -O #{Network}-topology-block.json https://hydra.iohk.io/build/7370192/download/1/#{Network}-topology.json
		cat <<< $(jq 'del(.Producers[])' #{Network}-topology-block.json) > #{Network}-topology-block.json
		cat <<< $(jq '.Producers += [{"addr": "relays-new.cardano-mainnet.iohk.io", "port": 3001, "valency": 2}]' #{Network}-topology-block.json) > #{Network}-topology-block.json

		# Init Relay Nodes
		wget -O #{Network}-topology-relay.json https://hydra.iohk.io/build/7370192/download/1/#{Network}-topology.json
		cat <<< $(jq 'del(.Producers[])' #{Network}-topology-relay.json) > #{Network}-topology-relay.json
		cat <<< $(jq '.Producers += [{"addr": "#{PublicNodeAddress}", "port": #{RelayNodePort}, "valency": 2}]' #{Network}-topology-relay.json) > #{Network}-topology-relay.json
		cat <<< $(jq '.Producers += [{"addr": "relays-new.cardano-mainnet.iohk.io", "port": 3001, "valency": 2}]' #{Network}-topology-relay.json) > #{Network}-topology-relay.json
	EOH
end

script "sync_block" do
	interpreter "bash"
	user "root"
	cwd "/root"
	code <<-EOH
		curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
		unzip awscliv2.zip
		sudo ./aws/install
		cd #{DatabasePath}
		rm -Rf *
		aws s3 cp s3://cardano-node/#{Network}/db.tar.gz #{CardanoPath}/db.#{Network}.tar.gz
		tar -xzvf #{CardanoPath}/db.#{Network}.tar.gz

		#Priv
		pool_exists=$(aws s3api head-object --bucket #{BackupBucket} --key priv/pool/#{ProjectTicker}/pool.cert || true)
		if [ -z "$pool_exists" ]; then
			echo "Pool does not exist, wait for init"
		else
			echo "Pool exists, sync from Cold Storage"
			mkdir -p #{CardanoPath}/priv/pool/#{ProjectTicker}
			aws s3 cp s3://#{BackupBucket}/priv/pool/#{ProjectTicker}/kes.skey #{CardanoPath}/priv/pool/#{ProjectTicker}/kes.skey
			aws s3 cp s3://#{BackupBucket}/priv/pool/#{ProjectTicker}/vrf.skey #{CardanoPath}/priv/pool/#{ProjectTicker}/vrf.skey
			chmod og-rwx #{CardanoPath}/priv/pool/#{ProjectTicker}/vrf.skey
			aws s3 cp s3://#{BackupBucket}/priv/pool/#{ProjectTicker}/pool.cert #{CardanoPath}/priv/pool/#{ProjectTicker}/pool.cert
		fi
		address_exists=$(aws s3api head-object --bucket #{BackupBucket} --key priv/wallet/operator/payment.vkey || true)
		if [ -z "$address_exists" ]; then
			echo "Address does not exist"
		else
			echo "Address exists, sync from Cold Storage"
			aws s3 cp s3://#{BackupBucket}/priv/wallet/operator/payment.vkey #{CardanoPath}/priv/wallet/operator/payment.vkey
			aws s3 cp s3://#{BackupBucket}/priv/wallet/operator/stake.vkey #{CardanoPath}/priv/wallet/operator/stake.vkey
		fi
	EOH
end

template 'env' do
	path "#{CardanoPath}/scripts/env"
	source 'env.block.erb'
	owner 'cardano'
	group 'cardano'
	mode 0700
end

template 'tail.sh' do
	path "#{CardanoPath}/scripts/tail.sh"
	source 'tail.sh.erb'
	owner 'cardano'
	group 'cardano'
	mode 0700
end

template 'topologyUpdater.sh' do
	path "/root/topologyUpdater.sh.relay.tmp"
	source 'topologyUpdater.sh.erb'
	owner 'cardano'
	group 'cardano'
	mode 0700
	variables( 
		BlockNodeAddress: BlockNodeAddress
	)
	action :create
end

script "prep_node" do
	interpreter "bash"
	user "cardano"
	cwd "/opt/cardano/cnode/scripts"
	code <<-EOH
		rm -Rf #{CardanoPath}/scripts/topologyUpdater.sh
		echo "Y" | ./deploy-as-systemd.sh
	EOH
end

script "start_node" do
	interpreter "bash"
	user "root"
	cwd "/root"
	code <<-EOH
		export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket
		aws s3 cp /root/topologyUpdater.sh.relay.tmp s3://#{BackupBucket}/scripts/topologyUpdater.sh.relay.tmp
		systemctl start cnode.service
	EOH
end

script "activate_block" do
	interpreter "bash"
	user "root"
	cwd "/root"
	code <<-EOH
		cat <<< $(jq '.Producers += [{"addr": "#{BlockNodeAddress}", "port": #{BlockNodePort}, "valency": 1}]' #{CardanoPath}/config/#{Network}/#{Network}-topology-block.json) > #{CardanoPath}/config/#{Network}/#{Network}-topology-block.json
		aws s3 cp #{CardanoPath}/config/#{Network}/#{Network}-topology-block.json s3://#{BackupBucket}/config/#{Network}/#{Network}-topology-block.json
	EOH
end