'use strict';

const basePath = '/app/cryptos';

const org = 'org1.example.com';

module.exports = {
  //loggerLevel: 'info',
  //loggerLevel: 'debug',
  loggerLevel: 'trace',

  user_id : `Admin@${org}`,
  msp_id : 'Org1MSP',

  privateKeyFolder : `${basePath}/users/Admin@${org}/msp/keystore`,
  signedCert : `${basePath}/users/Admin@${org}/msp/signcerts/Admin@${org}-cert.pem`,

  channel_id: 'mychannel',

  tls: false,
  peers: [
    {
      url: `grpcs://peer0.${org}:7051`,
      target_name: `peer0.${org}`,
      tls_cacerts: `${basePath}/peers/peer0.${org}/tls/server.crt`,
    },
    {
        url: `grpcs://peer1.${org}:8051`,
        target_name: `peer1.${org}`,
        tls_cacerts: `${basePath}/peers/peer1.${org}/tls/server.crt`,
    },
  ],
};






