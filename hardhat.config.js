require('dotenv').config()
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
	solidity: {
		compilers: [{
			version: "0.8.17",
			settings: {
				optimizer: {
					enabled: true,
					runs: 200
				}
			},
		}]
	},
	networks: {
		sepolia: {
		url: `${process.env.SEPOLIA_NETWORK}`,
		chainId: 11155111,
		accounts: [`${process.env.PRIVATEKEY}`]
		},
		mumbai: {
			url: `${process.env.MUMBAI_NETWORK}`,
			chainId: 80001,
			gasPrice: 'auto',
			accounts: [`${process.env.PRIVATEKEY}`],
		}
	}
};