#!/usr/bin/env bash

set -ex

# Ubuntu
if [ -f /etc/debian_version ]; then
    echo "Debian ... "
    apt-get update -y
    apt-get -y install wget
    wget -q http://repositories.sensuapp.org/apt/pubkey.gpg -O- | sudo apt-key add -
    echo "deb     http://repositories.sensuapp.org/apt sensu main" | sudo tee /etc/apt/sources.list.d/sensu.list
    apt-get update
    apt-get install sensu
elif [ -f /etc/redhat-release ]; then
    # Redhat/CentOS
    echo "Redhat/CentOS ... "
    rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-7.noarch.rpm
    yum install -y initscripts logrotate wget
    # sensu core
    echo '[sensu]
name=sensu
baseurl=http://repositories.sensuapp.org/yum/$basearch/
gpgcheck=0
enabled=1' | tee /etc/yum.repos.d/sensu.repo
    yum install sensu -y
else
    echo "Unknown OS ..."
    exit 1
fi

echo 'LOG_LEVEL=debug' >> /etc/default/sensu
echo "{
  \"rabbitmq\": {
   \"host\": \"${RABBITMQ_1_PORT_5672_TCP_ADDR-$1}\",
   \"vhost\": \"${RABBITMQ_1_ENV_RABBITMQ_DEFAULT_VHOST-/sensu}\",
   \"user\": \"${RABBITMQ_1_ENV_RABBITMQ_DEFAULT_USER-sensu}\",
   \"password\": \"${RABBITMQ_1_ENV_RABBITMQ_DEFAULT_PASS-secret}\",
   \"port\": \"${RABBITMQ_1_PORT_5672_TCP_PORT-5672}\"
  }
}" > /etc/sensu/config.json
wget -O /etc/sensu/conf.d/client.json http://sensuapp.org/docs/latest/files/client.json
sed -i -e s/localhost/`hostname`/ /etc/sensu/conf.d/client.json
chown -R sensu:sensu /etc/sensu
sensu-install -p disk-checks

/etc/init.d/sensu-client start

if [ -f /.dockerenv ]; then
  tail -f /var/log/sensu/sensu-client.log
fi
