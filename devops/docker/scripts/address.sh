#!/bin/bash

source vars.sh

###
### On air-gapped offline machine -  move to Lambda/S3
###

#Generate the Payment key pair
if [ ! -f $WALLETDIR/payment.skey ]; then
  cardano-cli address key-gen \
    --verification-key-file $WALLETDIR/payment.vkey \
    --signing-key-file $WALLETDIR/payment.skey
fi

#Generate the Stake key pair
if [ ! -f $WALLETDIR/stake.skey ]; then
  cardano-cli stake-address key-gen \
    --verification-key-file $WALLETDIR/stake.vkey \
    --signing-key-file $WALLETDIR/stake.skey
fi

#Generate the Payment address
if [ ! -f $WALLETDIR/payment.addr ]; then
  cardano-cli address build \
    --payment-verification-key-file $WALLETDIR/payment.vkey \
    --stake-verification-key-file $WALLETDIR/stake.vkey \
    --out-file $WALLETDIR/payment.addr \
    --${tip}
fi

#Generate the Stake/Reward address
if [ ! -f $WALLETDIR/reward.addr ]; then
  cardano-cli stake-address build \
    --stake-verification-key-file $WALLETDIR/stake.vkey \
    --out-file $WALLETDIR/reward.addr \
    --${tip}
fi