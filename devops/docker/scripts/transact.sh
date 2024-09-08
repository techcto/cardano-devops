#!/bin/bash

source vars.sh

transact(){
    DATE=$(date +%d%H%M)
    TRANSACTION=${cardano_path}/share/transactions/${DATE}
    mkdir -p ${TRANSACTION}

    echo PAYMENT: ${PAYMENT}
    echo FROM: $(cat $WALLETDIR/payment.addr)
    cardano-cli query utxo --address $(cat $WALLETDIR/payment.addr) --${tip}
    HASH=$(cardano-cli query utxo --address $(cat $WALLETDIR/payment.addr) --${tip} | tail -n1 | awk '{print $1;}')
    TXIX=$(cardano-cli query utxo --address $(cat $WALLETDIR/payment.addr) --${tip} | tail -n1 | awk '{print $2;}')
    BALANCE=$(cardano-cli query utxo --address $(cat $WALLETDIR/payment.addr) --${tip} | tail -n1 | awk '{print $3;}')
    REWARDS=$(cardano-cli query stake-address-info --${tip} --address $(cat $WALLETDIR/reward.addr) | jq -r ".[0].rewardAccountBalance")
    echo HASH: ${HASH}
    echo TXIX: ${TXIX}
    echo BALANCE: ${BALANCE}
    echo REWARDS: $REWARDS

    if [ $BALANCE ]; then
        #Determine the TTL (time to Live) for the transaction
        TTL=$(cardano-cli query tip --${tip} | jq '.slot')
        echo TTL: ${TTL}
        DELAY=200

        #Draft transaction
        TXOUT="--tx-out $(cat $WALLETDIR/payment.addr)+$(( ${BALANCE} - ${PAYMENT}))"
        WITHDRAW=""
        if [ $ADDRESSDEPOSIT ]; then 
            WITNESSES=2
            CERTS="--certificate-file $POOLDIR/stake.cert"
            TXOUT="--tx-out $(cat $WALLETDIR/payment.addr)+0"
            DELAY=0
        elif [ $GETREWARDS ]; then 
            WITNESSES=1
            CERTS=""
            TXOUT="--tx-out $(cat $WALLETDIR/payment.addr)+0"
            WITHDRAW="--withdrawal $(cat $WALLETDIR/reward.addr)+$REWARDS"
        elif [ $POOLDEPOSIT ]; then 
            WITNESSES=3
            TXOUT="--tx-out $(cat $WALLETDIR/payment.addr)+0"
            CERTS="--certificate-file $POOLDIR/pool.cert --certificate-file $POOLDIR/delegation.cert"
            DELAY=0
        elif [ $POOLREFUND ]; then 
            WITNESSES=1
            CERTS="--certificate-file $POOLDIR/pool.retirement"
            TXOUT="--tx-out $(cat $WALLETDIR/payment.addr)+0"
            DELAY=0
        elif [ $STAKEREFUND ]; then 
            WITNESSES=2
            CERTS="--certificate-file $POOLDIR/stake.retirement"
            TXOUT="--tx-out $(cat $WALLETDIR/payment.addr)+0"
            DELAY=0
        else
            WITNESSES=2
            CERTS=""
        fi

        cardano-cli transaction build-raw \
        --tx-in $HASH#$TXIX \
        ${TXOUT} \
        --invalid-hereafter $(($TTL + $DELAY)) \
        ${WITHDRAW} \
        --fee 0 \
        $CERTS \
        --out-file ${TRANSACTION}/tx.draft
        
        #Calculate fees
        echo "Calculate the fee"
        FEE=$(cardano-cli transaction calculate-min-fee \
            --tx-body-file ${TRANSACTION}/tx.draft \
            --tx-in-count 1 \
            --tx-out-count 1 \
            --witness-count ${WITNESSES} \
            --byron-witness-count 0 \
            --${tip} \
            --protocol-params-file ${POOLDIR}/protocol.json | awk '{print $1;}')
        echo Fee: ${FEE}

        if [ $STAKEREFUND ]; then 
            CHANGE=$(($BALANCE + $PAYMENT - $FEE))
        elif [ $GETREWARDS ]; then 
            CHANGE=$(($BALANCE + $REWARD - $FEE))
        else
            CHANGE=$(($BALANCE - $PAYMENT - $FEE))
        fi
        
        # if [ -z "$REWARD" ]; then
        #     CHANGE=$(($CHANGE + $REWARD))
        # fi
        echo CHANGE: ${CHANGE}

        #Build the transaction
        if [ $PAYEE ]; then 
            echo PAYEE: $PAYEE
            TXOUT="--tx-out $PAYEE+$PAYMENT --tx-out $(cat $WALLETDIR/payment.addr)+${CHANGE}"
        else
            TXOUT="--tx-out $(cat $WALLETDIR/payment.addr)+${CHANGE}"
        fi

        echo Build the transaction
        cardano-cli transaction build-raw \
        --tx-in $HASH#$TXIX \
        ${TXOUT} \
        --invalid-hereafter $(($TTL + $DELAY)) \
        ${WITHDRAW} \
        --fee $FEE \
        ${CERTS} \
        --out-file ${TRANSACTION}/tx.raw
        
        #Sign the transaction
        if [ $ADDRESSDEPOSIT ] || [ $GETREWARDS ]; then 
            KEYS="--signing-key-file $WALLETDIR/payment.skey --signing-key-file $WALLETDIR/stake.skey"
        elif [ $POOLDEPOSIT ]; then 
            KEYS="--signing-key-file $WALLETDIR/payment.skey --signing-key-file $POOLDIR/cold.skey --signing-key-file $WALLETDIR/stake.skey"
        elif [ $POOLREFUND ]; then 
            KEYS="--signing-key-file $WALLETDIR/payment.skey --signing-key-file $POOLDIR/cold.skey"
        else
            KEYS="--signing-key-file $WALLETDIR/payment.skey"
        fi

        echo Sign the transaction
        cardano-cli transaction sign \
        --tx-body-file ${TRANSACTION}/tx.raw \
        ${KEYS} \
        --${tip} \
        --out-file ${TRANSACTION}/tx.signed
        
        #Send the transaction
        echo Send the transaction
        cardano-cli transaction submit \
        --tx-file ${TRANSACTION}/tx.signed \
        --${tip}

        #Check the balances: Payer
        echo Payer Balance:
        cardano-cli query utxo \
            --address $(cat $WALLETDIR/payment.addr) \
            --${tip}

        if [ $PAYEE ]; then 
            #Check the balances: Payee
            echo Payee Balance:
            cardano-cli query utxo \
            --address $PAYEE \
            --${tip}
        fi

        unset PAYMENT
        unset PAYEE
    else
        echo "NOFUNDS: You have no funds.  Please add some funds in account $(cat $WALLETDIR/payment.addr) and try again."
        exit 0
    fi
}

export -f transact