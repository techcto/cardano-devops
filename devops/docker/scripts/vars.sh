#Get Tip network
export tip
if [ "${network}" == "testnet" ]; then
  tip="testnet-magic 1097911063"
else
  tip="mainnet"
fi
echo $tip

export CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket
export POOLDIR=${cardano_path}/share/priv/pool/cardano
export WALLETDIR=${cardano_path}/share/priv/wallet/cardano
mkdir -p $POOLDIR
mkdir -p $WALLETDIR

cardano-cli query protocol-parameters --${tip} --out-file $POOLDIR/protocol.json