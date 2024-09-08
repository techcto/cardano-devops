#Install Base
apt-get update
apt-get install automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev \
    libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool autoconf -y

apt-get install curl net-tools bc tcptraceroute iproute2 lsof rsync -y

apt-get install ca-certificates unzip python-is-python3 open-iscsi -y
systemctl enable --now iscsid

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli

#YQ
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
apt-get install jq  -y