#!/bin/bash

mkdir -p ${cardano_path}/share/config

#Init
init(){
    rm -Rf ${database_path}/*
    cd ${cardano_path}/share/config && ls -al

    #Metadata
    cat <<< $(jq '.name = "${project_name}"' /root/metadata.json) > metadata.json
    cat <<< $(jq '.description = "${project_description}"' metadata.json) > metadata.json
    cat <<< $(jq '.ticker = "${project_ticker}"' metadata.json) > metadata.json
    cat <<< $(jq '.homepage = "${project_homepage}"' metadata.json) > metadata.json

    if [ "${network}" == "testnet" ]; then
      mkdir -p testnet
      cd testnet
      #Testnet
      if [ ! -f testnet-topology-block.json ]; then
        wget https://hydra.iohk.io/build/7370192/download/1/testnet-config.json
        wget -O testnet-config-relay.json https://hydra.iohk.io/build/7370192/download/1/testnet-config.json
        sed -i testnet-config-relay.json -e "s/TraceMemPool\": true/TraceMemPool\": false/g"
        wget https://hydra.iohk.io/build/7370192/download/1/testnet-shelley-genesis.json
        wget https://hydra.iohk.io/build/7370192/download/1/testnet-byron-genesis.json
        wget https://hydra.iohk.io/build/7370192/download/1/testnet-alonzo-genesis.json
        wget https://hydra.iohk.io/build/7370192/download/1/testnet-db-sync-config.json
        # wget https://hydra.iohk.io/build/7370192/download/1/rest-config.json
        wget -O testnet-topology-relay.json https://hydra.iohk.io/build/7370192/download/1/testnet-topology.json
        wget -O testnet-topology-block.json https://hydra.iohk.io/build/7370192/download/1/testnet-topology.json
  
        # Init Relay Nodes
        # cat <<< $(jq '.Producers += [{"addr": "${public_node_addr}", "port": ${relay_node_port}, "valency": 1}]' testnet-topology-relay.json) > testnet-topology-relay.json
        cat <<< $(jq 'del(.Producers[])' testnet-topology-relay.json) > testnet-topology-relay.json
        # Init Block Producers
        cat <<< $(jq 'del(.Producers[])' testnet-topology-block.json) > testnet-topology-block.json
        cat <<< $(jq '.Producers += [{"addr": "relays-new.cardano-testnet.iohkdev.io", "port": 3001, "valency": 2}]' testnet-topology-block.json) > testnet-topology-block.json
      fi
    else
      mkdir -p mainnet
      cd mainnet
      if [ ! -f mainnet-topology-block.json ]; then
        wget https://hydra.iohk.io/build/7370192/download/1/mainnet-config.json
        wget -O mainnet-config-relay.json https://hydra.iohk.io/build/7370192/download/1/mainnet-config.json
        sed -i mainnet-config-relay.json -e "s/TraceMemPool\": true/TraceMemPool\": false/g"
        wget https://hydra.iohk.io/build/7370192/download/1/mainnet-byron-genesis.json
        wget https://hydra.iohk.io/build/7370192/download/1/mainnet-shelley-genesis.json
        wget https://hydra.iohk.io/build/7370192/download/1/mainnet-alonzo-genesis.json
        wget https://hydra.iohk.io/build/7370192/download/1/mainnet-db-sync-config.json
        wget -O mainnet-topology-relay.json https://hydra.iohk.io/build/7370192/download/1/mainnet-topology.json
        wget -O mainnet-topology-block.json https://hydra.iohk.io/build/7370192/download/1/mainnet-topology.json
        
        # Init Relay Nodes
        # cat <<< $(jq '.Producers += [{"addr": "${public_node_addr}", "port": ${relay_node_port}, "valency": 1}]' mainnet-topology-relay.json) > mainnet-topology-relay.json
        cat <<< $(jq '.Producers += [{"addr": "relays-new.cardano-mainnet.iohk.io", "port": 3001, "valency": 2}]' mainnet-topology-relay.json) > mainnet-topology-relay.json
        # Init Block Producers
        cat <<< $(jq 'del(.Producers[])' mainnet-topology-block.json) > mainnet-topology-block.json
        cat <<< $(jq '.Producers += [{"addr": "relays-new.cardano-mainnet.iohk.io", "port": 3001, "valency": 2}]' mainnet-topology-block.json) > mainnet-topology-block.json
        
        #https://explorer.cardano-mainnet.iohk.io/relays/topology.json
        sed -i mainnet-config.json -e "s/TraceBlockFetchDecisions\": false/TraceBlockFetchDecisions\": true/g" -e "s/127.0.0.1/0.0.0.0/g"
      fi
    fi
    
    #Back to root
    cd ../../
}

init