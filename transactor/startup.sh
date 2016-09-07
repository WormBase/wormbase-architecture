#!/bin/bash

cd /datomic
export DATOMIC_HOME=/datomic
export DATOMIC_NAME=datomic-pro-${DATOMIC_VERSION}
export DATOMIC_ZIP=${DATOMIC_NAME}.zip
export DATOMIC_DEPLOY_DIR=${DATOMIC_HOME}/${DATOMIC_NAME}

if [ -f "${DATOMIC_HOME}/bin/aws" ]
then
    EC2_ACCESS_KEY="${DATOMIC_READ_DEPLOY_ACCESS_KEY_ID}" EC2_SECRET_KEY="${DATOMIC_READ_DEPLOY_AWS_SECRET_KEY}" perl ${DATOMIC_HOME}/bin/aws get "${DATOMIC_DEPLOY_BUCKET}/${DATOMIC_VERSION}/${DATOMIC_ZIP}" > ${DATOMIC_ZIP}
    yum install -y unzip
else
    AWS_ACCESS_KEY_ID="${DATOMIC_READ_DEPLOY_ACCESS_KEY_ID}" AWS_SECRET_ACCESS_KEY="${DATOMIC_READ_DEPLOY_AWS_SECRET_KEY}" aws s3 cp s3://"${DATOMIC_DEPLOY_BUCKET}/${DATOMIC_VERSION}/${DATOMIC_ZIP}" ${DATOMIC_ZIP}
fi


echo $(cat "${DATOMIC_HOME}/aws.properties")

unzip ${DATOMIC_ZIP}
chown -R datomic ${DATOMIC_DEPLOY_DIR}
cd ${DATOMIC_DEPLOY_DIR}
. /etc/init.d/functions

echo "Running transactor with params:"
echo "${DATOMIC_DEPLOY_DIR}/bin/transactor -Xms$XMX -Xmx$XMX $JAVA_OPTS ${DATOMIC_HOME}/aws.properties"

daemon --user=datomic ${DATOMIC_DEPLOY_DIR}/bin/transactor -Xms$XMX -Xmx$XMX $JAVA_OPTS "${DATOMIC_HOME}/aws.properties" > ${DATOMIC_DEPLOY_DIR}/datomic-console.log 2>&1 &
sleep 20
export PID=`ps ax | grep transactor | grep java | grep -v grep | cut -c1-6`
echo "pid is $PID"
echo "DATOMIC_DISABLE_SHUTDOWN is ${DATOMIC_DISABLE_SHUTDOWN}"
if [ "$DATOMIC_DISABLE_SHUTDOWN" == "" ]; then
    while kill -0 $PID > /dev/null; do sleep 1; done
    echo "copying to s3"
    aws s3 cp ${DATOMIC_DEPLOY_DIR}/datomic-console.log s3://transactor-logs/
    tail -n 500 ${DATOMIC_DEPLOY_DIR}/datomic-console.log > /dev/console
    shutdown -h now
fi
