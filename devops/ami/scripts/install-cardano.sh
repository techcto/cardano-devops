# https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node/how-to-harden-ubuntu-server

#Cabal
wget https://downloads.haskell.org/~cabal/cabal-install-3.12.1.0/cabal-install-3.12.1.0-x86_64-ubuntu-16.04.tar.xz && \
    tar -xf cabal-install-3.12.1.0-x86_64-ubuntu-16.04.tar.xz && \
    rm cabal-install-3.12.1.0-x86_64-ubuntu-16.04.tar.xz && \
    ls -al && mv cabal /usr/local/bin/ && \
    cabal update && \
    cabal --version

#GHC
wget https://downloads.haskell.org/~ghc/9.10.1/ghc-9.10.1-x86_64-deb9-linux.tar.xz && \
    ls -al && \
    tar -xf ghc-9.10.1-x86_64-deb9-linux.tar.xz && \
    rm ghc-9.10.1-x86_64-deb9-linux.tar.xz && \
    ls -al && \
    cd ghc-9.10.1 && \
    ./configure && \
    make install && \
    ghc --version

#LibSodium
mkdir -p ~/cardano-src 
apt-get install -y libsodium-dev
# mkdir -p ~/cardano-src && cd ~/cardano-src && \
#     git clone https://github.com/input-output-hk/libsodium && \
#     cd libsodium && \
#     git checkout 66f017f1 && \
#     ./autogen.sh && \
#     ./configure && \
#     make && \
#     make install

#Cardano
cd ~/cardano-src && git clone https://github.com/input-output-hk/cardano-node.git && \
    cd cardano-node && \
    export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" && \
    export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" && \
    git fetch --all --recurse-submodules --tags && \
    git checkout $(curl -s https://api.github.com/repos/input-output-hk/cardano-node/releases/latest | jq -r .tag_name) && \
    cabal configure --with-compiler=ghc-9.10.1 && \
    echo "package cardano-crypto-praos" >>  cabal.project.local && \
    echo "  flags: -external-libsodium-vrf" >>  cabal.project.local && \
    cabal build all && \
    cp -p "$(./scripts/bin-path.sh cardano-node)" /usr/local/bin/ && \
    cp -p "$(./scripts/bin-path.sh cardano-cli)" /usr/local/bin/ && \
    cardano-cli --version && \
    cardano-node --version

#Cardano Wallet
WALLET_VERSION="v2021-05-26"
cd ~/cardano-src && git clone https://github.com/input-output-hk/cardano-wallet.git && \
    cd cardano-wallet && \
    export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" && \
    export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" && \
    git fetch --all --recurse-submodules --tags && \
    git checkout tags/${WALLET_VERSION} && \
    cabal configure --with-compiler=ghc-9.10.1 --constraint="random<1.2" && \
    echo "package cardano-crypto-praos" >>  cabal.project.local && \
    echo "  flags: -external-libsodium-vrf" >>  cabal.project.local && \
    cabal build all

HW_WALLET_VERSION="1.14.0" && \
    wget https://github.com/vacuumlabs/cardano-hw-cli/releases/download/v$HW_WALLET_VERSION/cardano-hw-cli_$HW_WALLET_VERSION-1.deb && \
    dpkg --install cardano-hw-cli_$HW_WALLET_VERSION-1.deb