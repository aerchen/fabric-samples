'use strict';

const basePath = '/app/msp';

module.exports = {
  loggerLevel: 'trace',

  user_id : 'Admin@org1.example.com',
  msp_id : 'Org1MSP',

  privateKeyFolder : basePath + '/keystore',
  signedCert : basePath + '/signcerts/Admin@org1.example.com-cert.pem',

  channel_id: 'mychannel',

  tls: false,
  peers: [
    {
      url: 'grpcs://peer0.org1.example.com:7051',
      target_name: 'peer0.org1.example.com',
    },
  ],
};






