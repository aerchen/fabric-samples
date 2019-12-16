#!/bin/bash
#
# Copyright Darren Chen. All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# replace certs of organization via fabric ca
function replaceOrgCerts() {
    echo ""
    echo "*************** start replace certs of ${ORG} ****************"
    echo ""

    WORK_DIR=$1
    ORG=$2
    NODE_TYPE=$3
    COUNT=$4

    echo "generate root cert of org: ${ORG}"
    ps -ef |grep ca-server | grep -v grep |awk '{print $2}'| xargs kill -9
    unset FABRIC_CA_HOME
    export FABRIC_CA_HOME=$WORK_DIR/ca-crypto/${ORG}

    fabric-ca-server start \
    -b admin:adminpw --csr.cn ca.${ORG} \
    --cfg.affiliations.allowremove \
    --cfg.identities.allowremove &

    sleep 1

    echo "generate ca client of org: ${ORG}"
    unset FABRIC_CA_CLIENT_HOME
    export FABRIC_CA_CLIENT_HOME=$FABRIC_CA_HOME/client
    fabric-ca-client enroll -u http://admin:adminpw@localhost:7054


    ##################
    echo "replace ca dir of org: ${ORG}"
    rm -rf $WORK_DIR/crypto-config/peerOrganizations/${ORG}/ca/*
    cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/peerOrganizations/${ORG}/ca/ca.${ORG}-cert.pem
    cp $FABRIC_CA_HOME/msp/keystore/*_sk $WORK_DIR/crypto-config/peerOrganizations/${ORG}/ca/

    echo "replace msp dir of org: ${ORG}"
    cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/${NODE_TYPE}Organizations/${ORG}/msp/cacerts/ca.${ORG}-cert.pem

    echo "replace users dir for org ${ORG}"
    fabric-ca-client register --id.secret password --id.type admin --id.name Admin@${ORG}
    fabric-ca-client enroll -u http://Admin@${ORG}:password@localhost:7054 -M $FABRIC_CA_HOME/users/Admin

    cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/${NODE_TYPE}Organizations/${ORG}/users/Admin@${ORG}/msp/cacerts/ca.${ORG}-cert.pem
    cp $FABRIC_CA_HOME/users/Admin/signcerts/cert.pem $WORK_DIR/crypto-config/${NODE_TYPE}Organizations/${ORG}/users/Admin@${ORG}/msp/signcerts/Admin@${ORG}-cert.pem
    rm -rf $WORK_DIR/crypto-config/${NODE_TYPE}Organizations/${ORG}/users/Admin@${ORG}/msp/keystore
    cp -r $FABRIC_CA_HOME/users/Admin/keystore $WORK_DIR/crypto-config/${NODE_TYPE}Organizations/${ORG}/users/Admin@${ORG}/msp/


    ##################
    echo "replace ${NODE_TYPE}s dir of org: ${ORG}"

    if [ "$NODE_TYPE" == "peer" ]; then
        for ((INDEX=0; INDEX<$COUNT; INDEX++));
        do
            replaceNode $WORK_DIR $ORG $NODE_TYPE $INDEX
        done
    else
        replaceNode $WORK_DIR $ORG $NODE_TYPE
        if [ $COUNT -ge 2 ]; then
            for INDEX in $(seq 2 $COUNT);
            do
                replaceNode $WORK_DIR $ORG $NODE_TYPE $INDEX
            done
        fi
    fi

    echo "************ replace certs of ${ORG} successfully ******************"
    echo ""
    echo "************ closeing ca server of ${ORG} ******************"
    ps -ef |grep ca-server | grep -v grep |awk '{print $2}'| xargs kill -9
    sleep 1
    echo ""
}

function replaceNode() {
    WORK_DIR=$1
    ORG=$2
    NODE_TYPE=$3
    INDEX=$4

    echo "replace certs of ${NODE_TYPE}${INDEX}.${ORG}"
    fabric-ca-client register --id.secret password --id.type ${NODE_TYPE} --id.name ${NODE_TYPE}${INDEX}.${ORG}
    fabric-ca-client enroll -u http://${NODE_TYPE}${INDEX}.${ORG}:password@localhost:7054 -M $FABRIC_CA_HOME/${NODE_TYPE}s/${NODE_TYPE}$INDEX

    cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/${NODE_TYPE}Organizations/${ORG}/${NODE_TYPE}s/${NODE_TYPE}${INDEX}.${ORG}/msp/cacerts/ca.${ORG}-cert.pem
    cp $FABRIC_CA_HOME/${NODE_TYPE}s/${NODE_TYPE}${INDEX}/signcerts/cert.pem $WORK_DIR/crypto-config/${NODE_TYPE}Organizations/${ORG}/${NODE_TYPE}s/${NODE_TYPE}${INDEX}.${ORG}/msp/signcerts/${NODE_TYPE}${INDEX}.${ORG}-cert.pem
    rm -rf $WORK_DIR/crypto-config/${NODE_TYPE}Organizations/${ORG}/${NODE_TYPE}s/${NODE_TYPE}${INDEX}.${ORG}/msp/keystore
    cp -r $FABRIC_CA_HOME/${NODE_TYPE}s/${NODE_TYPE}${INDEX}/keystore $WORK_DIR/crypto-config/${NODE_TYPE}Organizations/${ORG}/${NODE_TYPE}s/${NODE_TYPE}${INDEX}.${ORG}/msp/
}

