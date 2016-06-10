#!/usr/bin/env bash

set -ex

# Ubuntu
if [ -f /etc/debian_version ]; then
    echo "Debian ... "
    apt-get update -y
    apt-get -y install wget
    # If running with docker-compose,
    # we have official images for rabbitmq and redis.
    if [ ! -f /.dockerenv ]; then
        wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
        dpkg -i erlang-solutions_1.0_all.deb
        apt-get -y install erlang-nox

        wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.0/rabbitmq-server_3.6.0-1_all.deb
        dpkg -i rabbitmq-server_3.6.0-1_all.deb
        update-rc.d rabbitmq-server defaults
        /etc/init.d/rabbitmq-server start
        rabbitmqctl add_vhost /sensu
        rabbitmqctl add_user sensu secret
        rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"

        apt-get -y install redis-server
    fi
    wget -q http://repositories.sensuapp.org/apt/pubkey.gpg -O- | sudo apt-key add -
    echo "deb     http://repositories.sensuapp.org/apt sensu main" | sudo tee /etc/apt/sources.list.d/sensu.list
    apt-get update
    apt-get -y install sensu uchiwa
    update-rc.d sensu-server defaults
    update-rc.d sensu-api defaults
    update-rc.d uchiwa defaults
elif [ -f /etc/redhat-release ]; then
    # Redhat/CentOS
    echo "Redhat ... "
    #epel-release
    rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm
    yum install -y initscripts logrotate wget
    if [ ! -f /.dockerenv ]; then
        #erlang
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
    fi
    # sensu core
    echo '[sensu]
name=sensu
baseurl=http://repositories.sensuapp.org/yum/$basearch/
gpgcheck=0
enabled=1' | tee /etc/yum.repos.d/sensu.repo
    yum install sensu uchiwa -y
    /sbin/chkconfig sensu-server on
    /sbin/chkconfig sensu-api on
    /sbin/chkconfig uchiwa on
else
    echo "Unknown OS ..."
    exit 1
fi

# Add config files and start sensu services
echo "{
  \"rabbitmq\": {
       \"host\": \"${RABBITMQ_1_PORT_5672_TCP_ADDR-127.0.0.1}\",
       \"vhost\": \"${RABBITMQ_1_ENV_RABBITMQ_DEFAULT_VHOST-/sensu}\",
       \"user\": \"${RABBITMQ_1_ENV_RABBITMQ_DEFAULT_USER-sensu}\",
       \"password\": \"${RABBITMQ_1_ENV_RABBITMQ_DEFAULT_PASS-secret}\",
       \"port\": \"${RABBITMQ_1_PORT_5672_TCP_PORT-5672}\"
  },
  \"redis\": {
      \"host\": \"${REDIS_1_PORT_6379_TCP_ADDR-127.0.0.1}\",
      \"port\": \"${REDIS_1_PORT_6379_TCP_PORT-6379}\"
  },
  \"api\": {
      \"host\": \"127.0.0.1\",
      \"port\": 4567
  }

}" > /etc/sensu/config.json

wget -O /etc/sensu/conf.d/check_disk.json http://sensuapp.org/docs/latest/files/check_disk.json
wget -O /etc/sensu/conf.d/default_handler.json http://sensuapp.org/docs/latest/files/default_handler.json

echo 'LOG_LEVEL=debug' >> /etc/default/sensu
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
chown -R sensu:sensu /etc/sensu

/etc/init.d/sensu-server start
/etc/init.d/sensu-api start
/etc/init.d/uchiwa restart

if [ -f /.dockerenv ]; then
  tail -f /var/log/sensu/*.log
fi
