FROM ubuntu:18.04 as build

RUN apt-get update -y && \
    apt-get install build-essential pkg-config libffi-dev libgmp-dev -y && \
    apt-get install libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev -y && \
    apt-get install make g++ tmux git jq wget libncursesw5 libtool autoconf -y

#Cabal
RUN wget https://downloads.haskell.org/~cabal/cabal-install-3.4.0.0/cabal-install-3.4.0.0-x86_64-ubuntu-16.04.tar.xz && \
    tar -xf cabal-install-3.4.0.0-x86_64-ubuntu-16.04.tar.xz && \
    rm cabal-install-3.4.0.0-x86_64-ubuntu-16.04.tar.xz && \
    ls -al && mv cabal /usr/local/bin/ && \
    cabal update && \
    cabal --version

#GHC
RUN wget https://downloads.haskell.org/~ghc/8.10.4/ghc-8.10.4-x86_64-deb9-linux.tar.xz && \
    tar -xf ghc-8.10.4-x86_64-deb9-linux.tar.xz && \
    rm ghc-8.10.4-x86_64-deb9-linux.tar.xz && \
    cd ghc-8.10.4 && \
    ./configure && \
    make install && \
    ghc --version

#LibSodium
RUN mkdir -p ~/cardano-src && cd ~/cardano-src && \
    git clone https://github.com/input-output-hk/libsodium && \
    cd libsodium && \
    git checkout 66f017f1 && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install

#Cardano
RUN CARDANO_VERSION="1.29.0" && cd ~/cardano-src && git clone https://github.com/input-output-hk/cardano-node.git && \
    cd cardano-node && \
    export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" && \
    export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" && \
    git fetch --all --recurse-submodules --tags && \
    git checkout tags/${CARDANO_VERSION} && \
    cabal configure --with-compiler=ghc-8.10.4 && \
    echo "package cardano-crypto-praos" >>  cabal.project.local && \
    echo "  flags: -external-libsodium-vrf" >>  cabal.project.local && \
    cabal build all && \
    cp -p "$(./scripts/bin-path.sh cardano-node)" /usr/local/bin/ && \
    cp -p "$(./scripts/bin-path.sh cardano-cli)" /usr/local/bin/ && \
    cardano-cli --version && \
    cardano-node --version

FROM ubuntu:18.04 as wallet

COPY --from=build /usr/local/bin /usr/local/bin/
COPY --from=build /usr/local/lib /usr/local/lib/

RUN apt-get update -y && \
    apt-get install build-essential pkg-config libffi-dev libgmp-dev -y && \
    apt-get install libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev -y && \
    apt-get install make g++ tmux git jq wget libncursesw5 libtool autoconf -y

#LibSodium
RUN mkdir -p ~/cardano-src && cd ~/cardano-src && \
    git clone https://github.com/input-output-hk/libsodium && \
    cd libsodium && \
    git checkout 66f017f1 && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install

#Wallet
RUN WALLET_VERSION="v2021-05-26" && cd ~/cardano-src && git clone https://github.com/input-output-hk/cardano-wallet.git && \
    cd cardano-wallet && \
    export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" && \
    export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" && \
    git fetch --all --recurse-submodules --tags && \
    git checkout tags/${WALLET_VERSION} && \
    cabal update && \
    cabal configure --with-compiler=ghc-8.10.4 --constraint="random<1.2" && \
    echo "package cardano-crypto-praos" >>  cabal.project.local && \
    echo "  flags: -external-libsodium-vrf" >>  cabal.project.local && \
    cabal build all

FROM ubuntu:18.04 as prod

COPY --from=wallet /usr/local/bin /usr/local/bin/
COPY --from=wallet /usr/local/lib /usr/local/lib/
RUN apt-get update -y && apt-get install jq wget curl git net-tools bc tcptraceroute iproute2 lsof rsync sudo -y
RUN echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> $HOME/.bashrc && echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> $HOME/.bashrc && \
    exec bash && source $HOME/.bashrc

RUN HOME=/home/cardano && CNODE_HOME=/opt/cardano/cnode && \
    echo 'cardano ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    useradd -r -m -d $HOME cardano && \
    mkdir "$HOME/tmp";cd "$HOME/tmp" && \
    curl -sS -o prereqs.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/prereqs.sh && \
    chmod 755 prereqs.sh && \
    su -c "$HOME/tmp/prereqs.sh" - cardano