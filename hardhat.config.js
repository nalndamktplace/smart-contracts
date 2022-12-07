require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
	const accounts = await hre.ethers.getSigners();

	for (const account of accounts) {
		console.log(account.address);
	}
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	solidity: "0.8.13",
	defaultNetwork: "hardhat",
	networks: {
		goerli: {
			url: `https://goerli.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
			accounts: [`${process.env.PRIVATE_KEY}`],
		},
		sepolia: {
			url: `https://sepolia.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
			accounts: [`${process.env.PRIVATE_KEY}`],
		},
		mumbai: {
			url: `https://matic-mumbai.chainstacklabs.com`,
			accounts: [`${process.env.PRIVATE_KEY}`],
		},
		hedera: {
			url: 'https://testnet.hashio.io/api',
			chainId: 296,
			accounts: [`${process.env.HEDERA_EVM_PVT_KEY}`],
		},
		hardhat: {
			gas: 12000000,
			blockGasLimit: 0x1fffffffffffff,
			allowUnlimitedContractSize: true,
			timeout: 1800000,
		},
	}
};
