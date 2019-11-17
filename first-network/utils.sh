#!/bin/bash
#
# Copyright Darren Chen All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# replace orderers certs via fabric ca
function replaceOrderers() {
    echo ""
    echo "*************** start replace certs of orderers ****************"

    ORG=$1
    COUNT=$2
    WORK_DIR=$PWD

    echo "generate ca cert for org ${ORG}"
    ps -ef |grep ca-server | grep -v grep |awk '{print $2}'| xargs kill -9
    unset FABRIC_CA_HOME
    export FABRIC_CA_HOME=$WORK_DIR/ca-crypto/${ORG}

    fabric-ca-server start \
    -b admin:adminpw --csr.cn ca.${ORG} \
    --cfg.affiliations.allowremove \
    --cfg.identities.allowremove &

    sleep 2

    echo "replace msp certs"
    cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/msp/cacerts/ca.${ORG}-cert.pem


    ##################
    echo "generate ca client for org ${ORG}"
    unset FABRIC_CA_CLIENT_HOME
    export FABRIC_CA_CLIENT_HOME=$FABRIC_CA_HOME/client
    fabric-ca-client enroll -u http://admin:adminpw@localhost:7054


    ##################
    echo "generate admin user for org ${ORG}"
    fabric-ca-client register --id.secret password --id.type admin --id.name Admin@${ORG}
    fabric-ca-client enroll -u http://Admin@${ORG}:password@localhost:7054 -M $FABRIC_CA_HOME/users/Admin

    echo "replace users certs & key"

    cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/users/Admin@${ORG}/msp/cacerts/ca.${ORG}-cert.pem
    cp $FABRIC_CA_HOME/users/Admin/signcerts/cert.pem $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/users/Admin@${ORG}/msp/signcerts/Admin@${ORG}-cert.pem
    rm -rf $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/users/Admin@${ORG}/msp/keystore
    cp -r $FABRIC_CA_HOME/users/Admin/keystore $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/users/Admin@${ORG}/msp/

    ##################
    echo "generate certs for orderers"

    echo "replace certs & key for orderer"
    fabric-ca-client register --id.secret password --id.type orderer --id.name orderer.${ORG}
    fabric-ca-client enroll -u http://orderer.${ORG}:password@localhost:7054 -M $FABRIC_CA_HOME/orderers/orderer

    cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/orderers/orderer.${ORG}/msp/cacerts/ca.${ORG}-cert.pem
    cp $FABRIC_CA_HOME/orderers/orderer/signcerts/cert.pem $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/orderers/orderer.${ORG}/msp/signcerts/orderer.${ORG}-cert.pem
    rm -rf $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/orderers/orderer.${ORG}/msp/keystore
    cp -r $FABRIC_CA_HOME/orderers/orderer/keystore $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/orderers/orderer.${ORG}/msp/


    if [ $COUNT -ge 2 ]; then
        for INDEX in $(seq 2 $COUNT);
        do
            echo "replace certs & key for orderer${INDEX}"
            fabric-ca-client register --id.secret password --id.type orderer --id.name orderer${INDEX}.${ORG}
            fabric-ca-client enroll -u http://orderer${INDEX}.${ORG}:password@localhost:7054 -M $FABRIC_CA_HOME/orderers/orderer$INDEX

            cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/orderers/orderer${INDEX}.${ORG}/msp/cacerts/ca.${ORG}-cert.pem
            cp $FABRIC_CA_HOME/orderers/orderer${INDEX}/signcerts/cert.pem $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/orderers/orderer${INDEX}.${ORG}/msp/signcerts/orderer${INDEX}.${ORG}-cert.pem
            rm -rf $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/orderers/orderer${INDEX}.${ORG}/msp/keystore
            cp -r $FABRIC_CA_HOME/orderers/orderer${INDEX}/keystore $WORK_DIR/crypto-config/ordererOrganizations/${ORG}/orderers/orderer${INDEX}.${ORG}/msp/
        done
    fi

    echo "************replace orderer successfully******************"
    ps -ef |grep ca-server | grep -v grep |awk '{print $2}'| xargs kill -9
    echo ""
}

# replace peers certs via fabric ca
function replacePeers() {
    echo ""
    echo "*************** start replace certs of peers ****************"

    ORG=$1
    COUNT=$2
    WORK_DIR=$PWD

    echo "generate ca cert for org ${ORG}"
    ps -ef |grep ca-server | grep -v grep |awk '{print $2}'| xargs kill -9
    unset FABRIC_CA_HOME
    export FABRIC_CA_HOME=$WORK_DIR/ca-crypto/${ORG}

    fabric-ca-server start \
    -b admin:adminpw --csr.cn ca.${ORG} \
    --cfg.affiliations.allowremove \
    --cfg.identities.allowremove &

    sleep 2

    echo "replace msp certs"
    cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/peerOrganizations/${ORG}/msp/cacerts/ca.${ORG}-cert.pem


    ##################
    echo "generate ca client for org ${ORG}"
    unset FABRIC_CA_CLIENT_HOME
    export FABRIC_CA_CLIENT_HOME=$FABRIC_CA_HOME/client
    fabric-ca-client enroll -u http://admin:adminpw@localhost:7054


    ##################
    echo "generate admin user for org ${ORG}"
    fabric-ca-client register --id.secret password --id.type admin --id.name Admin@${ORG}
    fabric-ca-client enroll -u http://Admin@${ORG}:password@localhost:7054 -M $FABRIC_CA_HOME/users/Admin

    echo "replace users certs & key"

    cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/peerOrganizations/${ORG}/users/Admin@${ORG}/msp/cacerts/ca.${ORG}-cert.pem
    cp $FABRIC_CA_HOME/users/Admin/signcerts/cert.pem $WORK_DIR/crypto-config/peerOrganizations/${ORG}/users/Admin@${ORG}/msp/signcerts/Admin@${ORG}-cert.pem
    rm -rf $WORK_DIR/crypto-config/peerOrganizations/${ORG}/users/Admin@${ORG}/msp/keystore
    cp -r $FABRIC_CA_HOME/users/Admin/keystore $WORK_DIR/crypto-config/peerOrganizations/${ORG}/users/Admin@${ORG}/msp/

    ##################
    echo "generate certs for peers"

    for ((INDEX=0; INDEX<$COUNT; INDEX++));
    do
        echo "replace certs & key for peer${INDEX}"
        fabric-ca-client register --id.secret password --id.type peer --id.name peer${INDEX}.${ORG}
        fabric-ca-client enroll -u http://peer${INDEX}.${ORG}:password@localhost:7054 -M $FABRIC_CA_HOME/peers/peer$INDEX

        cp $FABRIC_CA_HOME/ca-cert.pem $WORK_DIR/crypto-config/peerOrganizations/${ORG}/peers/peer${INDEX}.${ORG}/msp/cacerts/ca.${ORG}-cert.pem
        cp $FABRIC_CA_HOME/peers/peer${INDEX}/signcerts/cert.pem $WORK_DIR/crypto-config/peerOrganizations/${ORG}/peers/peer${INDEX}.${ORG}/msp/signcerts/peer${INDEX}.${ORG}-cert.pem
        rm -rf $WORK_DIR/crypto-config/peerOrganizations/${ORG}/peers/peer${INDEX}.${ORG}/msp/keystore
        cp -r $FABRIC_CA_HOME/peers/peer${INDEX}/keystore $WORK_DIR/crypto-config/peerOrganizations/${ORG}/peers/peer${INDEX}.${ORG}/msp/
    done

    echo "************replace orderer successfully******************"
    ps -ef |grep ca-server | grep -v grep |awk '{print $2}'| xargs kill -9
    echo ""
}




