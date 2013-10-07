#!/usr/bin/env bash

STORM_VERSION="0.9.0-rc2"
STORM_URL="https://dl.dropboxusercontent.com/s/p5wf0hsdab5n9kn/storm-0.9.0-rc2.zip"
ZOOKEEPER_VERSION="3.4.5"
ZEROMQ_VERSION="2.1.7"

gpg --keyserver pgp.mit.edu --recv-keys F758CE318D77295D
gpg --export --armor F758CE318D77295D | sudo apt-key add -

gpg --keyserver pgp.mit.edu --recv-keys 2B5C1B00
gpg --export --armor 2B5C1B00 | sudo apt-key add -

apt-get update
apt-get install -y software-properties-common
apt-get install -y python-software-properties
apt-get install -y apache2
rm -rf /var/www
ln -fs /vagrant /var/www

add-apt-repository ppa:webupd8team/java
apt-get update
# auto-accept oracle licence
sudo echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get install -y oracle-java7-installer

export JAVA_HOME=/usr/lib/jvm/java-7-oracle/

# zookeeper
echo "Currently in: `pwd`"
wget -q http://ftp.piotrkosoft.net/pub/mirrors/ftp.apache.org/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz
tar zxf zookeeper-$ZOOKEEPER_VERSION.tar.gz
cp zookeeper-$ZOOKEEPER_VERSION/conf/zoo_sample.cfg zookeeper-$ZOOKEEPER_VERSION/conf/zoo.cfg

# 0mq
echo "Currently in: `pwd`"
sudo apt-get install -y g++ uuid-dev make
wget -q http://download.zeromq.org/zeromq-$ZEROMQ_VERSION.tar.gz
tar -xzf zeromq-$ZEROMQ_VERSION.tar.gz
cd zeromq-$ZEROMQ_VERSION
./configure
make
make install
cd ~vagrant

#install jzmq
echo "Currently in: `pwd`"
sudo apt-get install -y git pkg-config autoconf libtool
git clone https://github.com/nathanmarz/jzmq.git
cd jzmq
./autogen.sh
./configure

# workaround for https://github.com/zeromq/jzmq/issues/114
touch src/classdist_noinst.stamp
cd src/
CLASSPATH=.:./.:$CLASSPATH javac -d . org/zeromq/ZMQ.java org/zeromq/App.java org/zeromq/ZMQForwarder.java org/zeromq/EmbeddedLibraryTools.java org/zeromq/ZMQQueue.java org/zeromq/ZMQStreamer.java org/zeromq/ZMQException.java

make
make install
cd ~vagrant

# storm
echo "Currently in: `pwd`"
sudo apt-get install -y unzip
wget -q -O storm-$STORM_VERSION.zip $STORM_URL
unzip storm-$STORM_VERSION.zip

sudo apt-get install -y supervisor

# supervisor conf
cat > /etc/supervisor/conf.d/storm.conf << DELIM
[program:storm-nimbus]
command=/home/vagrant/storm-$STORM_VERSION/bin/storm nimbus
user=storm
autostart=true
autorestart=true
startsecs=10
startretries=999
log_stdout=true
log_stderr=true
logfile=/var/log/storm/nimbus.out
logfile_maxbytes=20MB
logfile_backups=10

[program:storm-ui]
command=/home/vagrant/storm-$STORM_VERSION/bin/storm ui
user=storm
autostart=true
autorestart=true
startsecs=10
startretries=999
log_stdout=true
log_stderr=true
logfile=/var/log/storm/ui.out
logfile_maxbytes=20MB
logfile_backups=10

[program:storm-supervisor]
command=/home/vagrant/storm-$STORM_VERSION/bin/storm supervisor
user=storm
autostart=true
autorestart=true
startsecs=10
startretries=999
log_stdout=true
log_stderr=true
logfile=/var/log/storm/supervisor.out
logfile_maxbytes=20MB
logfile_backups=10

[program:zookeeper]
command=/home/vagrant/zookeeper-$ZOOKEEPER_VERSION/bin/zkServer.sh start-foreground
autorestart=true
stopsignal=KILL

DELIM


sudo supervisorctl reload
