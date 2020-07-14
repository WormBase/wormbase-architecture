#!/bin/bash

cd /datomic
export DATOMIC_HOME=/datomic
export DATOMIC_NAME=datomic-pro-${DATOMIC_VERSION}
export DATOMIC_ZIP=${DATOMIC_NAME}.zip
export DATOMIC_DEPLOY_DIR=${DATOMIC_HOME}/${DATOMIC_NAME}

ID=$$

DEPS_INSTALLER=/tmp/install_tx_deps.sh

if [ ! -z $DATOMIC_TRANSACTOR_DEPS_SCRIPT ]; then
    echo "Fetching datomic transactor deps script" >> /tmp/debugging.log
    wget -O $DEPS_INSTALLER $DATOMIC_TRANSACTOR_DEPS_SCRIPT
    chmod +x $DEPS_INSTALLER
    /bin/bash $DEPS_INSTALLER
    if [ ! -z $DATOMIC_EXT_CLASSPATH_SCRIPT ]; then
	wget -O /tmp/build_datomic_ext_classpath.sh $DATOMIC_EXT_CLASSPATH_SCRIPT
	chmod +x /tmp/build_datomic_ext_classpath.sh
	echo "Setting DATOMIC_EXT_CLASSPATH_SCRIPT" >> /tmp/debugging.log
	export DATOMIC_EXT_CLASSPATH="$(su - datomic -c 'CONSOLE_DEVICE=/dev/console /tmp/build_datomic_ext_classpath.sh')"
    fi
fi

if [ -z $DATOMIC_EXT_CLASSPATH ]; then
    echo "DATOMIC_EXT_CLASSPATH was not set or empty" >> /tmp/debugging.log
else
    echo "ENV: DATOMIC_EXT_CLASSPATH=$DATOMIC_EXT_CLASSPATH" >> /tmp/debugging.log
fi

printenv >> /tmp/debugging.log

if [ -f "${DATOMIC_HOME}/bin/aws" ]
then
    EC2_ACCESS_KEY="${DATOMIC_READ_DEPLOY_ACCESS_KEY_ID}" EC2_SECRET_KEY="${DATOMIC_READ_DEPLOY_AWS_SECRET_KEY}" perl ${DATOMIC_HOME}/bin/aws get "${DATOMIC_DEPLOY_BUCKET}/${DATOMIC_VERSION}/${DATOMIC_ZIP}" > ${DATOMIC_ZIP}
    yum install -y unzip
else
    AWS_ACCESS_KEY_ID="${DATOMIC_READ_DEPLOY_ACCESS_KEY_ID}" AWS_SECRET_ACCESS_KEY="${DATOMIC_READ_DEPLOY_AWS_SECRET_KEY}" aws s3 cp s3://"${DATOMIC_DEPLOY_BUCKET}/${DATOMIC_VERSION}/${DATOMIC_ZIP}" ${DATOMIC_ZIP}
fi

unzip ${DATOMIC_ZIP} > /dev/null
chown -R datomic ${DATOMIC_DEPLOY_DIR}
cd ${DATOMIC_DEPLOY_DIR}
. /etc/init.d/functions

echo "Running transactor with params:" >> /tmp/debugging.log
echo "${DATOMIC_DEPLOY_DIR}/bin/transactor -Xms$XMX -Xmx$XMX $JAVA_OPTS ${DATOMIC_HOME}/aws.properties" >> /tmp/debugging.log

# temporary debugging.
aws s3 cp ${DATOMIC_HOME}/aws.properties s3://transactor-logs/aws.properties.$ID


echo "export DATOMIC_EXT_CLASSPATH=$DATOMIC_EXT_CLASSPATH" >> ~datomic/.bash_profile
chown datomic ~datomic/.bash_profile

daemon \
    --user=datomic ${DATOMIC_DEPLOY_DIR}/bin/transactor \
    -Xms$XMX \
    -Xmx$XMX \
    $JAVA_OPTS \
    "${DATOMIC_HOME}/aws.properties" > ${DATOMIC_DEPLOY_DIR}/datomic-console_$ID.log 2>&1 &
sleep 20

export PID=`ps ax | grep transactor | grep java | grep -v grep | cut -c1-6`
echo "pid is $PID"

# Temp debug log upload
aws s3 cp /tmp/debugging.log s3://transactor-logs/

if [ "$DATOMIC_DISABLE_SHUTDOWN" == "" ]; then
    while kill -0 $PID > /dev/null; do sleep 1; done
    echo "copying to s3"
    aws s3 cp ${DATOMIC_DEPLOY_DIR}/datomic-console_$ID.log s3://transactor-logs/
    tail -n 500 ${DATOMIC_DEPLOY_DIR}/datomic-console_$ID.log >> /tmp/debugging.log
    sleep 20
    shutdown -h now
fi
