#!/bin/sh
set -e

echo "Post job"
export http_proxy=${proxy}
export https_proxy=${proxy}
export no_proxy="localhost,.hm.dm.ad"
echo "Download binaries"

curl -LO https://github.com/disaster37/elktools/releases/download/v7.5.1-4/elktools_v7.5.1-4_linux_amd64
mv elktools_v7.5.1-4_linux_amd64 elktools
chmod +x elktools
export PATH=$PWD:$PATH

# Wait elasticsearch respond
set +e
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate check-elasticsearch-status
state=$?
if [ $state -ne 0 -a $state -ne 1 ]; then
    echo "Wait Elasticsearch respond"
    while [ $state -ne 0 -a $state -ne 1 ]; do
        sleep 10
        elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate check-elasticsearch-status
        state=$?
    done
fi
set -e

echo "Put Elasticsearch online"
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate enable-routing-allocation
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate disable-ml-upgrade
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate start-watcher-service
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate start-ilm-service
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate start-slm-service

# Wait Elasticseach on green state
set +e
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate check-elasticsearch-status
state=$?
if [ $state -ne 0 ]; then
    echo "Wait Elasticsearch in green state"
    while [ $state -ne 0 ]; do
        sleep 10
        elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate check-elasticsearch-status
        state=$?
    done
fi
set -e

echo "Pre stop executed surccessfully"