#!/bin/bash

source vars.sh
source transact.sh

#Get current Epoch
epochLength=$(cat ${cardano_path}/share/config/${network}/${network}-shelley-genesis.json | jq -r '.epochLength')
currentSlot=$(cardano-cli query tip --${tip} | jq -r '.slot')
currentEpoch=$((currentSlot / epochLength))

#Generate deregistration certificate
cardano-cli stake-address deregistration-certificate \
  --staking-verification-key-file $POOLDIR/stake.vkey \
  --out-file $POOLDIR/stake.retirement

#Deregister Stake
export STAKEREFUND=$(cat $POOLDIR/protocol.json | jq -r .stakeAddressDeposit)
echo STAKEREFUND: $STAKEREFUND
export PAYMENT=$STAKEREFUND
transact
unset STAKEREFUND