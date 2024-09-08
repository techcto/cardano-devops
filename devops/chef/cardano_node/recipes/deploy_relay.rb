CardanoPath = node[:install][:CardanoPath]
DatabasePath = node[:install][:DatabasePath]
Network = node[:install][:Network]
RelayNodePort = node[:install][:RelayNodePort]
BackupBucket = node[:install][:BackupBucket]

script "config_relay" do
	interpreter "bash"
	user "root"
	cwd "/root"
	code <<-EOH
		curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
		unzip awscliv2.zip
		sudo ./aws/install
		mkdir -p #{CardanoPath}/config/#{Network}
		cd #{CardanoPath}/config/#{Network}
		wget -O #{Network}-config-relay.json https://hydra.iohk.io/build/7370192/download/1/#{Network}-config.json
		sed -i #{Network}-config-relay.json -e "s|TraceBlockFetchDecisions\": false|TraceBlockFetchDecisions\": true|g" -e "s|127.0.0.1|0.0.0.0|g"
		sed -i #{Network}-config-relay.json -e "s|TraceMemPool\": true|TraceMemPool\": false|g"
		wget https://hydra.iohk.io/build/7370192/download/1/#{Network}-byron-genesis.json
		wget https://hydra.iohk.io/build/7370192/download/1/#{Network}-shelley-genesis.json
		wget https://hydra.iohk.io/build/7370192/download/1/#{Network}-alonzo-genesis.json

		aws s3 cp s3://#{BackupBucket}/config/#{Network}/#{Network}-topology-block.json #{CardanoPath}/config/#{Network}/#{Network}-topology-block.json
	EOH
end

script "sync_relay" do
	interpreter "bash"
	user "root"
	cwd "/root"
	code <<-EOH
		cd #{DatabasePath}
		rm -Rf *
		aws s3 cp s3://cardano-node/#{Network}/db.tar.gz #{CardanoPath}/db.#{Network}.tar.gz
		tar -xzvf #{CardanoPath}/db.#{Network}.tar.gz
	EOH
end

template 'env' do
	path "#{CardanoPath}/scripts/env"
	source 'env.erb'
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

script "prep_node" do
	interpreter "bash"
	user "cardano"
	cwd "/opt/cardano/cnode/scripts"
	code <<-EOH
		aws s3 cp s3://#{BackupBucket}/scripts/topologyUpdater.sh.relay.tmp topologyUpdater.sh
		chmod 700 topologyUpdater.sh
		echo "Y" | ./deploy-as-systemd.sh
	EOH
end

script "start_node" do
	interpreter "bash"
	user "root"
	cwd "/root"
	code <<-EOH
		systemctl start cnode.service
	EOH
end

script "nginx" do
	interpreter "bash"
	user "root"
	cwd "/root"
	code <<-EOH
		apt install nginx -y
	EOH
end

script "start_web" do
	interpreter "bash"
	user "root"
	cwd "/root"
	code <<-EOH
		chown -Rf www-data.www-data /var/www/html
		service nginx start
	EOH
end