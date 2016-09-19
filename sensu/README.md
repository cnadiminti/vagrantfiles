# What is it for?

An example [Sensu](https://sensuapp.org/) deployment.

:information_source: Last verified with Sensu 0.26.1-1.

## Server node
- create a server VM
- install and configure sensu-server along with dependencies
- install uchiwa

## Client node
- create a client VM
- install and configure sensu-client
- install example plugin

## Deployment diagram

#### Deployment Diagram for Vagrant
![Deployment Diagram for Vagrant](images/deployment_vagrant.png)

#### Deployment Diagram for Docker
![Deployment Diagram for Docker](images/deployment_docker.png)

# How to run?

#### vagrant

Just run `vagrant up` and open https://127.0.0.1:3000

#### docker-compose

Just run `docker-compose up` and open https://127.0.0.1:3000
