# Smart contracts for Nalnda Marketplace

Mint test Nalnda tokens using: https://mint-nalnda.netlify.app/

Hardhat commands:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```

Nalnda ERC20 test token deployed to:

1. Rinkeby: 0x16B05d9d5AB2e1369faFDEAd000770C1F2621841
2. Ropsten: 0x4e965B1F0A61C06f17312E5989CAB18d8E33755b
3. Mumbai: 0x1Dd5Ee08A759059E0E7734C9d2e4FEde0eD5F865

### Deploy contracts:

Step 1: Update the NALNDA_ERC20 in the .env file.

Step 2: Run command:
```shell
npx hardhat run scripts/deployContracts.js --network <BLOCKCHAIN_NETWORK>
```
> BLOCKCHAIN_NETWORK should be mumbai, rinkeby or ropsten.

### Deploy a new Nalnda ERC20 test token:

```shell
npx hardhat run scripts/deployNalndaToken.js --network <BLOCKCHAIN_NETWORK>
```
> BLOCKCHAIN_NETWORK should be mumbai, rinkeby or ropsten.
