#!/usr/bin/env bash

set -e

# Ubuntu
if [ -f /etc/debian_version ]; then
    apt-get update -y
    apt-get -y install wget
    wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
    dpkg -i erlang-solutions_1.0_all.deb
    #apt-get update
    apt-get -y install erlang-nox

    wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.0/rabbitmq-server_3.6.0-1_all.deb
    dpkg -i rabbitmq-server_3.6.0-1_all.deb
    update-rc.d rabbitmq-server defaults
    /etc/init.d/rabbitmq-server start
    rabbitmqctl add_vhost /sensu
    rabbitmqctl add_user sensu secret
    rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"

    apt-get -y install redis-server

    wget -q http://repositories.sensuapp.org/apt/pubkey.gpg -O- | sudo apt-key add -
    echo "deb     http://repositories.sensuapp.org/apt sensu main" | sudo tee /etc/apt/sources.list.d/sensu.list
    apt-get update
    apt-get -y install sensu
    wget -O /etc/sensu/config.json http://sensuapp.org/docs/latest/files/config.json
    wget -O /etc/sensu/conf.d/check_disk.json http://sensuapp.org/docs/latest/files/check_disk.json
    wget -O /etc/sensu/conf.d/default_handler.json http://sensuapp.org/docs/latest/files/default_handler.json
    echo 'LOG_LEVEL=debug' >> /etc/default/sensu
    chown -R sensu:sensu /etc/sensu
    /etc/init.d/sensu-server start
    /etc/init.d/sensu-api start
    update-rc.d sensu-server defaults
    update-rc.d sensu-api defaults

    #wget http://dl.bintray.com/palourde/uchiwa/uchiwa_0.14.5-1_amd64.deb
    #dpkg -i uchiwa_0.14.5-1_amd64.deb
    apt-get -y install uchiwa

    echo '{
  "sensu": [
    {
      "name": "Site 1",
      "host": "0.0.0.0",
      "port": 4567,
      "timeout": 10
    }
  ],
  "uchiwa": {
    "host": "0.0.0.0",
    "port": 3000,
    "refresh": 10
  }
}' > /etc/sensu/uchiwa.json
    /etc/init.d/uchiwa restart
elif [ -f /etc/redhat-release ]; then
    # Redhat/CentOS
    echo "Redhat/CentOS ... "
    #epel-release
    rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm

    #erlang
    yum install wget -y
    rpm -Uvh http://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
    yum install -y erlang

    # rabbitmq
    rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
    yum install -y initscripts logrotate
    rpm -Uvh http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.0/rabbitmq-server-3.6.0-1.noarch.rpm
    /etc/init.d/rabbitmq-server start
    chkconfig rabbitmq-server on
    rabbitmqctl add_vhost /sensu
    rabbitmqctl add_user sensu secret
    rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"

    yum install -y redis
    service redis restart
    /sbin/chkconfig redis on
    redis-cli ping

    # sensu core
    yum install -y initscripts logrotate wget
    echo '[sensu]
name=sensu
baseurl=http://repositories.sensuapp.org/yum/$basearch/
gpgcheck=0
enabled=1' | tee /etc/yum.repos.d/sensu.repo
    yum install sensu -y
    wget -O /etc/sensu/config.json http://sensuapp.org/docs/latest/files/config.json
    sed -i -e s/localhost/127.0.0.1/ /etc/sensu/config.json
    wget -O /etc/sensu/conf.d/check_disk.json http://sensuapp.org/docs/latest/files/check_disk.json
    wget -O /etc/sensu/conf.d/default_handler.json http://sensuapp.org/docs/latest/files/default_handler.json
    echo 'LOG_LEVEL=debug' >> /etc/default/sensu
    chown -R sensu:sensu /etc/sensu
    /etc/init.d/sensu-server start
    /etc/init.d/sensu-api start
    /sbin/chkconfig sensu-server on
    /sbin/chkconfig sensu-api on

    # uchiwa
    yum -y install uchiwa
    /sbin/chkconfig uchiwa on
    echo '{
  "sensu": [
    {
      "name": "Site 1",
      "host": "0.0.0.0",
      "port": 4567,
      "timeout": 10
    }
  ],
  "uchiwa": {
    "host": "0.0.0.0",
    "port": 3000,
    "refresh": 10
  }
}' > /etc/sensu/uchiwa.json
    /etc/init.d/uchiwa restart
else
    echo "Unknown OS ..."
    exit 1
fi
