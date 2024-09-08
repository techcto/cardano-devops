#!/bin/bash
export CARDANO_NODE_SOCKET_PATH="/opt/cardano/cnode/sockets/node0.socket"
export public_node_addr=$public_node_addr
export relay_node_port=$relay_node_port
export network=$network
export database_path=$database_path
export socket_path=$socket_path

#Init
source ./scripts/vars.sh

mv ./scripts/env ${cardano_path}/scripts/env
mv ./scripts/tail.sh ${cardano_path}/scripts/tail.sh

#Sync Blockchain
rsync -avu ${cardano_path}/share/db/${network}/ ${database_path}

cd ${cardano_path}/scripts
echo "Y" | ./deploy-as-systemd.sh
systemctl start cnode.service
cat <<< $(jq '.Producers += [{"addr": "'${public_node_addr}'", "port": ${relay_node_port}, "valency": 1}]' ${cardano_path}/share/config/${network}/${network}-topology-relay.json) > ${cardano_path}/share/config/${network}/${network}-topology-relay.json

./cnode.sh