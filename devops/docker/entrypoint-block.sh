#!/bin/bash
export CARDANO_NODE_SOCKET_PATH="/opt/cardano/cnode/sockets/node0.socket"
export project_name=$project_name
export project_description=$project_description
export project_ticker=$project_ticker
export project_homepage=$project_homepage
export relay_node_port=$relay_node_port
export block_node_addr=$block_node_addr
export block_node_port=$block_node_port
export network=$network
export database_path=$database_path
export socket_path=$socket_path

#Init
source ./scripts/vars.sh
source ./scripts/init.sh

mv ./scripts/env.block ${cardano_path}/scripts/env
mv ./scripts/tail.sh ${cardano_path}/scripts/tail.sh

#Sync Blockchain
if [ -f ${cardano_path}/share/db/${network}/protocolMagicId ]; then
  rsync -avu ${cardano_path}/share/db/${network}/ ${database_path}
else
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  cd ${database_path}
  rm -Rf *
  aws s3 cp s3://cardano-node/${network}/db.tar.gz ${cardano_path}/db.${network}.tar.gz
  tar -xzvf ${cardano_path}/db.${network}.tar.gz
  rsync -avu ${database_path}/ ${cardano_path}/share/db/${network}
fi

cd ${cardano_path}/scripts
echo "Y" | ./deploy-as-systemd.sh
systemctl start cnode.service
cat <<< $(jq '.Producers += [{"addr": "'$block_node_addr'", "port": #{block_node_port}, "valency": 1}]' ${cardano_path}/share/config/${network}/${network}-topology-block.json) > ${cardano_path}/share/config/${network}/${network}-topology-block.json

./cnode.sh