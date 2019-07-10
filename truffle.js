module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 6283185
    },
    solc: {
     optimizer: { // Turning on compiler optimization that removes some local variables during compilation
       enabled: true,
       runs: 200
      }
    }
  }
};
