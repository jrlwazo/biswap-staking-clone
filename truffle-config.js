const HDWalletProvider = require('@truffle/hdwallet-provider');
const mnemonic = ''

module.exports = {
  networks: {
    // development: {
    //   host: "127.0.0.1",     // Localhost (default: none)
    //   port: 7545,            // Standard Ethereum port (default: none)
    //   network_id: "97",       // Any network (default: none)
    // },
    bscTestnet: {
      provider: () => new HDWalletProvider(mnemonic, 'https://data-seed-prebsc-1-s1.binance.org:8545'
      ),
      network_id: 97,
      skipDryRun: true
    },
  },
  compilers: {
    solc: {
      version: "pragma",// "0.8.10",
      settings: {
        optimizer: {
          enabled: true,
          runs: 999999
        },
        // evmVersion: "istanbul"
      }
    }
  },
  db: {
    enabled: false
  }
};
