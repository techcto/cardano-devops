#user
HOME=/home/cardano
CNODE_HOME=/opt/cardano/cnode
echo 'cardano ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
useradd -r -m -d $HOME cardano
usermod -aG sudo cardano

mkdir "$HOME/tmp";cd "$HOME/tmp"
curl -sfS -o guild-deploy.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/guild-deploy.sh && chmod 770 guild-deploy.sh && chown cardano guild-deploy.sh
sudo -u cardano ./guild-deploy.sh -s dl -b master -n mainnet -t cnode -p /opt/cardano

echo "Finish Cardano"