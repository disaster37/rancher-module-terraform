#!/bin/sh
set -e

echo "Pre job"
export http_proxy=${proxy}
export https_proxy=${proxy}
export no_proxy="localhost,.hm.dm.ad"
echo "Download binaries"

curl -LO https://github.com/disaster37/elktools/releases/download/v7.5.1-3/elktools_v7.5.1-3_linux_amd64
mv elktools_v7.5.1-3_linux_amd64 elktools
chmod +x elktools
export PATH=$PWD:$PATH

# Wait Elasticseach on green state
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

echo "Put Elasticsearch on downtime"
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate disable-routing-allocation
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate enable-ml-upgrade
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate stop-watcher-service
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate stop-ilm-service
elktools --url ${ELASTIC_URL} --user ${ELASTIC_USERNAME} --password ${ELASTIC_PASSWORD} --self-signed-certificate stop-slm-service
echo "Pre stop executed surccessfully"