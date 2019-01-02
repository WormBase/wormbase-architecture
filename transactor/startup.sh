#!/bin/bash

cd /datomic
export DATOMIC_HOME=/datomic
export DATOMIC_NAME=datomic-pro-${DATOMIC_VERSION}
export DATOMIC_ZIP=${DATOMIC_NAME}.zip
export DATOMIC_DEPLOY_DIR=${DATOMIC_HOME}/${DATOMIC_NAME}

[ ! -z $DATOMIC_EXT_CLASSPATH_SCRIPT ] && wget -O /tmp/build_datomic_ext_classpath.sh $DATOMIC_EXT_CLASSPATH_SCRIPT
[ -f /tmp/build_datomic_ext_classpath.sh ] && chmod +x /tmp/build_datomic_ext_classpath.sh
[ -f /tmp/build_datomic_ext_classpath.sh ] && \
    export DATOMIC_EXT_CLASSPATH="$(su - datomic -c 'CONSOLE_DEVICE=/dev/stderr /tmp/build_datomic_ext_classpath.sh')"

[ ! -z $DATOMIC_TRANSACTOR_DEPS_SCRIPT ] && wget -O /tmp/install_tx_deps.sh $DATOMIC_TRANSACTOR_DEPS_SCRIPT
[ -f /tmp/intall_tx_deps.sh ] && chmod +x /tmp/intall_tx_deps.sh && /tmp/install_tx_deps.sh    

printenv > /dev/console

if [ -f "${DATOMIC_HOME}/bin/aws" ]
then
    EC2_ACCESS_KEY="${DATOMIC_READ_DEPLOY_ACCESS_KEY_ID}" EC2_SECRET_KEY="${DATOMIC_READ_DEPLOY_AWS_SECRET_KEY}" perl ${DATOMIC_HOME}/bin/aws get "${DATOMIC_DEPLOY_BUCKET}/${DATOMIC_VERSION}/${DATOMIC_ZIP}" > ${DATOMIC_ZIP}
    yum install -y unzip
else
    AWS_ACCESS_KEY_ID="${DATOMIC_READ_DEPLOY_ACCESS_KEY_ID}" AWS_SECRET_ACCESS_KEY="${DATOMIC_READ_DEPLOY_AWS_SECRET_KEY}" aws s3 cp s3://"${DATOMIC_DEPLOY_BUCKET}/${DATOMIC_VERSION}/${DATOMIC_ZIP}" ${DATOMIC_ZIP}
fi

unzip ${DATOMIC_ZIP}
chown -R datomic ${DATOMIC_DEPLOY_DIR}
cd ${DATOMIC_DEPLOY_DIR}
. /etc/init.d/functions

 echo "Running transactor with params:"
echo "${DATOMIC_DEPLOY_DIR}/bin/transactor -Xms$XMX -Xmx$XMX $JAVA_OPTS ${DATOMIC_HOME}/aws.properties"
aws s3 cp ${DATOMIC_HOME}/aws.properties s3://transactor-logs/aws.properties.wb-names

echo "export DATOMIC_EXT_CLASSPATH=$DATOMIC_EXT_CLASSPATH" >> ~datomic/.bash_profile
chown datomic ~datomic/.bash_profile

daemon \
    --user=datomic ${DATOMIC_DEPLOY_DIR}/bin/transactor \
    -Xms$XMX \
    -Xmx$XMX \
    $JAVA_OPTS \
    "${DATOMIC_HOME}/aws.properties" > ${DATOMIC_DEPLOY_DIR}/datomic-console.log 2>&1 &
echo
echo "**************** START DEBUG ******************"
cat ${DATOMIC_DEPLOY_DIR}/datomic-console.log
echo
echo "**************** END DEBUG ******************"
echo
sleep 20

export PID=`ps ax | grep transactor | grep java | grep -v grep | cut -c1-6`
echo "pid is $PID"

if [ "$DATOMIC_DISABLE_SHUTDOWN" == "" ]; then
    while kill -0 $PID > /dev/null; do sleep 1; done
    echo "copying to s3"
    aws s3 cp ${DATOMIC_DEPLOY_DIR}/datomic-console.log s3://transactor-logs/
    tail -n 500 ${DATOMIC_DEPLOY_DIR}/datomic-console.log > /dev/console
    sleep 20
    shutdown -h now
fi
