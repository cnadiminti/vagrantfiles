#!/usr/bin/env bash

set -e

# Ubuntu
if [ -f /etc/debian_version ]; then
    apt-get update
    wget -q http://repositories.sensuapp.org/apt/pubkey.gpg -O- | sudo apt-key add -
    echo "deb     http://repositories.sensuapp.org/apt sensu main" | sudo tee /etc/apt/sources.list.d/sensu.list
    apt-get update
    apt-get install sensu
    echo 'LOG_LEVEL=debug' >> /etc/default/sensu
    #wget -O /etc/sensu/config.json http://sensuapp.org/docs/0.21/files/config.json
    echo '{
  "rabbitmq": {
    "host": "192.168.56.101",
    "vhost": "/sensu",
    "user": "sensu",
    "password": "secret"
  }
}' > /etc/sensu/config.json
    wget -O /etc/sensu/conf.d/client.json http://sensuapp.org/docs/latest/files/client.json
    sed -ie s/localhost/192.168.56.101/ /etc/sensu/conf.d/client.json
    chown -R sensu:sensu /etc/sensu
    sensu-install -p disk-checks
    /etc/init.d/sensu-client start
elif [ -f /etc/redhat-release ]; then
    # Redhat/CentOS
    echo "Redhat/CentOS ... "
    rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm
    yum install -y initscripts logrotate wget

    # sensu core
    echo '[sensu]
name=sensu
baseurl=http://repositories.sensuapp.org/yum/$basearch/
gpgcheck=0
enabled=1' | tee /etc/yum.repos.d/sensu.repo
    yum install sensu -y
    echo 'LOG_LEVEL=debug' >> /etc/default/sensu
    echo '{
  "rabbitmq": {
    "host": "192.168.56.101",
    "vhost": "/sensu",
    "user": "sensu",
    "password": "secret"
  }
}' > /etc/sensu/config.json
    wget -O /etc/sensu/conf.d/client.json http://sensuapp.org/docs/latest/files/client.json
    sed -i -e s/localhost/192.168.56.101/ /etc/sensu/conf.d/client.json
    chown -R sensu:sensu /etc/sensu
    sensu-install -p disk-checks
    chown -R sensu:sensu /etc/sensu
    /etc/init.d/sensu-client start
    /sbin/chkconfig sensu-client on
else
    echo "Unknown OS ..."
    exit 1
fi
