#!/bin/bash -e

cd /datomic
export DATOMIC_HOME=/datomic
export DATOMIC_NAME=datomic-pro-${DATOMIC_VERSION}
export DATOMIC_ZIP=${DATOMIC_NAME}.zip
export DATOMIC_DEPLOY_DIR=${DATOMIC_HOME}/${DATOMIC_NAME}

ID=$$

DEPS_INSTALLER=/tmp/install_tx_deps.sh


file_log () {
    local msg=$1
    echo $msg >> /tmp/debugging.log
}

console_log () {
    local msg=$1
    echo $msg >> /dev/console
}

if [ ! -z $DATOMIC_TRANSACTOR_DEPS_SCRIPT ]; then
    echo "Fetching datomic transactor deps script" >> /tmp/debugging.log
    wget -O $DEPS_INSTALLER $DATOMIC_TRANSACTOR_DEPS_SCRIPT
    chmod +x $DEPS_INSTALLER
    /bin/bash $DEPS_INSTALLER
    if [ ! -z $DATOMIC_EXT_CLASSPATH_SCRIPT ]; then
        wget -O /tmp/build_datomic_ext_classpath.sh $DATOMIC_EXT_CLASSPATH_SCRIPT
        chmod +x /tmp/build_datomic_ext_classpath.sh
	file_log "stat /tmp/build_datomic_ext_classpath.sh:"
	file_log $(stat /tmp/build_datomic_ext_classpath.sh)
        file_log $(cat /tmp/build_datomic_ext_classpath.sh)
        file_log "Setting DATOMIC_EXT_CLASSPATH_SCRIPT"
	file_log "output of runing DATOMIC_EXT_CLASSPATH_SCRIPT:"
	file_log $(su - datomic -c 'CONSOLE_DEVICE=/tmp/debugging.log /tmp/build_datomic_ext_classpath.sh')
        export DATOMIC_EXT_CLASSPATH="$(su - datomic -c 'CONSOLE_DEVICE=/tmp/debugging.log /tmp/build_datomic_ext_classpath.sh')"
    fi
fi

if [ -z $DATOMIC_EXT_CLASSPATH ]; then
    file_log "DATOMIC_EXT_CLASSPATH was not set or empty"
    console_log "DATOMIC_EXT_CLASSPATH was not set or empty"
else
    file_log "ENV: DATOMIC_EXT_CLASSPATH=$DATOMIC_EXT_CLASSPATH"
    console_log "ENV: DATOMIC_EXT_CLASSPATH=$DATOMIC_EXT_CLASSPATH"
fi

file_log "ALL ENV VARS:"
file_log $(printenv)

if [ -f "${DATOMIC_HOME}/bin/aws" ]
then
    EC2_ACCESS_KEY="${DATOMIC_READ_DEPLOY_ACCESS_KEY_ID}" EC2_SECRET_KEY="${DATOMIC_READ_DEPLOY_AWS_SECRET_KEY}" perl ${DATOMIC_HOME}/bin/aws get "${DATOMIC_DEPLOY_BUCKET}/${DATOMIC_VERSION}/${DATOMIC_ZIP}" > ${DATOMIC_ZIP}
    yum install -y unzip > /dev/null 2> /dev/null
else
    AWS_ACCESS_KEY_ID="${DATOMIC_READ_DEPLOY_ACCESS_KEY_ID}" AWS_SECRET_ACCESS_KEY="${DATOMIC_READ_DEPLOY_AWS_SECRET_KEY}" aws s3 cp s3://"${DATOMIC_DEPLOY_BUCKET}/${DATOMIC_VERSION}/${DATOMIC_ZIP}" ${DATOMIC_ZIP} > /dev/null 2>/dev/null
fi

unzip ${DATOMIC_ZIP} > /dev/null 2 > /dev/null
chown -R datomic ${DATOMIC_DEPLOY_DIR}
cd ${DATOMIC_DEPLOY_DIR}
. /etc/init.d/functions

for fn in file_log console_log; do
    $fn "Running transactor with params:"
    $fn "${DATOMIC_DEPLOY_DIR}/bin/transactor -Xms$XMX -Xmx$XMX $JAVA_OPTS ${DATOMIC_HOME}/aws.properties"
done

echo "export DATOMIC_EXT_CLASSPATH=$DATOMIC_EXT_CLASSPATH" >> ~datomic/.bash_profile
file_log "datomic USER's bash profile:"
file_log $(cat ~datomic/.bash_profile)

chown datomic ~datomic/.bash_profile

console_log "Starting datomic transactor..."
daemon \
    --user=datomic ${DATOMIC_DEPLOY_DIR}/bin/transactor \
    -Xms$XMX \
    -Xmx$XMX \
    $JAVA_OPTS \
    "${DATOMIC_HOME}/aws.properties" > ${DATOMIC_DEPLOY_DIR}/datomic-console_$ID.log 2>&1 &
sleep 20

export PID=`ps ax | grep transactor | grep java | grep -v grep | cut -c1-6`
console_log "Datomic transactor pid is $PID"

# Temp debug log upload
aws s3 cp /tmp/debugging.log s3://transactor-logs/

if [ "$DATOMIC_DISABLE_SHUTDOWN" == "" ]; then
    while kill -0 $PID > /dev/null; do sleep 1; done
    aws s3 cp ${DATOMIC_DEPLOY_DIR}/datomic-console_$ID.log s3://transactor-logs/
    sleep 20
    shutdown -h now
fi
