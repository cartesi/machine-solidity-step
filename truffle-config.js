const HDWalletProvider = require("@truffle/hdwallet-provider");
const project = process.env.PROJECT_ID;
const mnemonic = process.env.MNEMONIC;

const network = (name, network_id) => ({
  provider: () => new HDWalletProvider(mnemonic, `https://${name}.infura.io/v3/${project}`),
  network_id,
  gas: 4700000
});

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    ganache: {
      host: "ganache",
      port: 8545,
      network_id: "*",
    },
    geth: {
      host: "geth",
      port: 8545,
      network_id: "15",
    },
    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8555,         // <-- If you change this, also set the port option in .solcover.js.
      gas: 0xfffffffffff, // <-- Use this high gas value
      gasPrice: 0x01      // <-- Use this low gas price
    },
    ropsten: network('ropsten', 3),
    kovan: network('kovan', 42),
    rinkeby: network('rinkeby', 4)
  }
};
