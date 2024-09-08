
apt update -y
wget https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_linux-x64_bin.tar.gz
tar xvf openjdk-16.0.2_linux-x64_bin.tar.gz
mv jdk-16.0.2 /opt/jdk16

tee /etc/profile.d/jdk16.sh <<EOF
export JAVA_HOME=/opt/jdk16
export PATH=\$PATH:\$JAVA_HOME/bin
EOF

source /etc/profile.d/jdk16.sh

echo $JAVA_HOME
java -version

mkdir -p /opt/jormanager && cd /opt/jormanager
wget -O jormanager.jar https://bitbucket.org/muamw10/jormanager/downloads/jormanager-4.1.4-SNAPSHOT.jar
java -jar jormanager.jar install