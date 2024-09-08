#!/bin/bash

source vars.sh
source transact.sh

BALANCE=$(cardano-cli query utxo --address $(cat $WALLETDIR/payment.addr) --${tip} | tail -n1 | awk '{print $3;}')
if [ ! $BALANCE ]; then
  echo "NOFUNDS: You have no funds.  Please add some funds in account $(cat $WALLETDIR/payment.addr) and try again."
  exit 0
fi

#Register Stake Address on the Blockchain
if [ ! -f $POOLDIR/stake.cert ]; then
  #Create a registration certificate
  cardano-cli stake-address registration-certificate \
    --stake-verification-key-file $WALLETDIR/stake.vkey \
    --out-file $POOLDIR/stake.cert

  #Add stake to your stake address.
  export ADDRESSDEPOSIT=$(cat $POOLDIR/protocol.json | jq -r .stakeAddressDeposit)
  export PAYMENT=${ADDRESSDEPOSIT}
  transact
  unset ADDRESSDEPOSIT
fi

if [ -f $POOLDIR/protocol.json ] && [ ! -f $POOLDIR/pool.id ]; then
  #Metadata Hash
  cardano-cli stake-pool metadata-hash --pool-metadata-file ${cardano_path}/share/config/metadata.json > $POOLDIR/poolMetaDataHash.txt

  #Pool Cost
  POOLCOST=$(cat $POOLDIR/protocol.json | jq -r .minPoolCost)
  echo POOLCOST: ${POOLCOST}

  #Pool Registration Certificate
  PLEDGE=<%= node[:install][:Pledge] %>
  MARGIN=<%= node[:install][:Margin] %>
  RELAY="<%= node[:install][:FQDN] %>"
  cardano-cli stake-pool registration-certificate \
    --cold-verification-key-file $POOLDIR/cold.vkey \
    --vrf-verification-key-file $POOLDIR/vrf.vkey \
    --pool-pledge $PLEDGE \
    --pool-cost $POOLCOST \
    --pool-margin $MARGIN \
    --pool-reward-account-verification-key-file $WALLETDIR/stake.vkey \
    --pool-owner-stake-verification-key-file $WALLETDIR/stake.vkey \
    --${tip} \
    --multi-host-pool-relay $RELAY \
    --pool-relay-port $relay_node_port \
    --metadata-url http://$RELAY/metadata.json \
    --metadata-hash $(cat $POOLDIR/poolMetaDataHash.txt) \
    --out-file $POOLDIR/pool.cert

  if [ -f $POOLDIR/pool.cert ] && [ ! -f $POOLDIR/pool.id ]; then
    cardano-cli stake-address delegation-certificate \
      --stake-verification-key-file $WALLETDIR/stake.vkey \
      --cold-verification-key-file $POOLDIR/cold.vkey \
      --out-file $WALLETDIR/delegation.cert

    #Pledge stake to your stake pool
    export POOLDEPOSIT=$(cat $POOLDIR/protocol.json | jq '.stakePoolDeposit')
    export PAYMENT=${POOLDEPOSIT}
    transact
    $POOLDEPOSIT=null

    #Verify Stakepool
    echo Verify Stakepool
    cardano-cli stake-pool id --cold-verification-key-file $POOLDIR/cold.vkey --output-format hex > $POOLDIR/pool.id
    cat $POOLDIR/pool.id
    #A non-empty string return means you're registered! 
    cardano-cli query stake-snapshot --stake-pool-id $(cat $POOLDIR/pool.id) --${tip} 
  fi
else
  #A non-empty string return means you're registered! 
  if [ -f $POOLDIR/pool.id ]; then
    cardano-cli query stake-snapshot --stake-pool-id $(cat $POOLDIR/pool.id) --${tip} 
  else
    echo "ERROR"
    exit 1
  fi
fi