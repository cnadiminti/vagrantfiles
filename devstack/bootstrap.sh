#! /bin/bash

set -e

p_dir=$(dirname "$0")

function run_unstack {
    if [ -d "${p_dir}/devstack" ]; then
        echo '--------------- Running unstack.sh -----------'
        "${p_dir}"/devstack/unstack.sh
        echo '--------------- Running clean.sh -----------'
        "${p_dir}"/devstack/clean.sh
    fi
}

function clone_devstack {
    echo '--------------- Cloning fresh devstack -----------'
    if [ -d "${p_dir}/devstack" ]; then
        rm -rf "${p_dir}/devstack"
    fi
    git clone https://github.com/openstack-dev/devstack -b stable/liberty "${p_dir}/devstack"
}

function run_stack {
    echo '--------------- Running stack.sh -----------'
    cp "${p_dir}/local.conf" "${p_dir}/devstack/local.conf"
    "${p_dir}"/devstack/stack.sh
}

run_unstack || true
clone_devstack
run_stack

