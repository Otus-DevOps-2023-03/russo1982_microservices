#!/bin/bash

mongod --fork --logpath /var/log/mongodb/mongodb.log --config /etc/mongodb.conf --dbpath /var/lib/mongodb

source /reddit/db_config

cd /reddit && puma || exit
