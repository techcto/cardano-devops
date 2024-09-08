#!/bin/bash

source vars.sh

#Transact
source transact.sh

#Test Payment
export PAYEE="addr_test1qr39fq82f9dfjvhu4psx6wcr2cned6raa49ja0emz835h72fvty9ururdm2gzwqzj0aptlg2uumm55hc9r7a9laavavqzhd7qh"
export PAYMENT=1000000
echo PAYMENT: ${PAYMENT}
transact
PAYMENT=null


    #Funding
    #TODO: Get API Key
    # echo "Funding Payment Address: "$(cat keys/payment.addr)
    # curl -XPOST https://faucet.cardano-testnet.iohkdev.io/send-money/$(cat keys/payment.addr)
    # echo "Awaiting funds..." && sleep 60
    # cardano-cli query utxo ${tip} --address $(cat keys/payment.addr)