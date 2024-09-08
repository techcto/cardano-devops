#!/bin/bash

source vars.sh

BALANCE=$(cardano-cli query utxo --address $(cat $WALLETDIR/payment.addr) --${tip} | tail -n1 | awk '{print $3;}')
if [ ! $BALANCE ]; then
  echo "NOFUNDS: You have no funds.  Please add some funds in account $(cat $WALLETDIR/payment.addr) and try again."
  exit 0
fi

#Generate Cold Keys and a Cold_counter
#DANGER: Always rotate KES keys using the latest cold.counter
cardano-cli node key-gen \
  --cold-verification-key-file $POOLDIR/cold.vkey \
  --cold-signing-key-file $POOLDIR/cold.skey \
  --operational-certificate-issue-counter-file $POOLDIR/cold.counter

  #Extremely sensitive key, upload cold.skey offsite
  # aws s3 cp $POOLDIR/cold.skey s3://cardano-node/${project_name}/cold/cold.skey

#Generate VRF Key pair
#Required to start a stake pool's block producing node
if [ ! -f $POOLDIR/vrf.skey ]; then
  cardano-cli node key-gen-VRF \
    --verification-key-file $POOLDIR/vrf.vkey \
    --signing-key-file $POOLDIR/vrf.skey
fi
chmod og-rwx $POOLDIR/vrf.skey

#Generate the KES Key pair
#KES keys are used to generate a stake pool's operational certificate, which expires within 90 days of that opcert's specified KES period
cardano-cli node key-gen-KES \
  --verification-key-file $POOLDIR/kes.vkey \
  --signing-key-file $POOLDIR/kes.skey

#Get KESPeriod
slotsPerKESPeriod=$(cat ${cardano_path}/share/config/${network}/${network}-shelley-genesis.json | jq '.slotsPerKESPeriod')
maxKESEvolutions=$(cat ${cardano_path}/share/config/${network}/${network}-shelley-genesis.json | jq '.slotsPerKESPeriod')
currentSlot=$(cardano-cli query tip --${tip} | jq -r '.slot')
echo "slotsPerKESPeriod="$slotsPerKESPeriod
KESPeriod=$((currentSlot / slotsPerKESPeriod))
echo $KESPeriod > $POOLDIR/kes.start
echo "KESPeriod="$KESPeriod

#Generate the Operational Certificate
cardano-cli node issue-op-cert \
  --kes-verification-key-file $POOLDIR/kes.vkey \
  --cold-signing-key-file $POOLDIR/cold.skey \
  --operational-certificate-issue-counter $POOLDIR/cold.counter \
  --kes-period $KESPeriod \
  --out-file $POOLDIR/op.cert