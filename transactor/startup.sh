#!/bin/bash

cd /datomic
export DATOMIC_HOME=/datomic
export DATOMIC_NAME=datomic-pro-${DATOMIC_VERSION}
export DATOMIC_ZIP=${DATOMIC_NAME}.zip
export DATOMIC_DEPLOY_DIR=${DATOMIC_HOME}/${DATOMIC_NAME}

ID=$$

DEPS_INSTALLER=/tmp/install_tx_deps.sh
LOGFILE=/tmp/startup.log
echo "" > ${LOGFILE}
chmod a+w ${LOGFILE}

if [ ! -z $DATOMIC_TRANSACTOR_DEPS_SCRIPT ]; then
    wget -O $DEPS_INSTALLER $DATOMIC_TRANSACTOR_DEPS_SCRIPT
    chmod +x $DEPS_INSTALLER

    echo "DEPS_INSTALLER log:" >> ${LOGFILE}
    echo "-------------------" >> ${LOGFILE}
    /bin/bash $DEPS_INSTALLER &>> ${LOGFILE}
    echo "---" >> ${LOGFILE}

    if [ ! -z $DATOMIC_EXT_CLASSPATH_SCRIPT ]; then
        wget -O /tmp/build_datomic_ext_classpath.sh $DATOMIC_EXT_CLASSPATH_SCRIPT
        chmod +x /tmp/build_datomic_ext_classpath.sh
        echo "BUILD_EXT_CLASSPATH log:" >> ${LOGFILE}
        echo "------------------------" >> ${LOGFILE}
        export DATOMIC_EXT_CLASSPATH="$(su - datomic -c 'CONSOLE_DEVICE=/dev/null ARTIFACT_VERSION='"$ARTIFACT_VERSION"' /tmp/build_datomic_ext_classpath.sh 2>> '"$LOGFILE")"
        echo "---" >> ${LOGFILE}
    fi
else
    echo "DATOMIC_TRANSACTOR_DEPS_SCRIPT was not set" >> ${LOGFILE}
    echo "Not setting DATOMIC_EXT_CLASSPATH" >> ${LOGFILE}
fi

printenv >> ${LOGFILE}
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

echo "Running transactor with params:" >> ${LOGFILE}
echo "${DATOMIC_DEPLOY_DIR}/bin/transactor -Xms$XMX -Xmx$XMX $JAVA_OPTS ${DATOMIC_HOME}/aws.properties"  >> ${LOGFILE}

# debug logging
aws s3 cp ${DATOMIC_HOME}/aws.properties s3://transactor-logs/CF/$CF_STACK_NAME/$EC2_INSTANCE_ID/aws.properties.$ID
# Intermediate startup log file upload
aws s3 cp ${LOGFILE} s3://transactor-logs/CF/$CF_STACK_NAME/$EC2_INSTANCE_ID/


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
echo "datomic transactor pid is $PID" >> ${LOGFILE}

if [ "$DATOMIC_DISABLE_SHUTDOWN" == "" ]; then
    while kill -0 $PID > /dev/null; do sleep 1; done
    # debug logging
    echo "Datomic transactor stopped." >> ${LOGFILE}
    echo "Copying log files to s3, and shutting down instance." >> ${LOGFILE}
    aws s3 cp ${DATOMIC_DEPLOY_DIR}/datomic-console_$ID.log s3://transactor-logs/CF/$CF_STACK_NAME/$EC2_INSTANCE_ID/
    aws s3 cp ${LOGFILE} s3://transactor-logs/CF/$CF_STACK_NAME/$EC2_INSTANCE_ID/
    tail -n 500 ${DATOMIC_DEPLOY_DIR}/datomic-console_$ID.log > /dev/console

    sleep 20

    shutdown -h now
fi
