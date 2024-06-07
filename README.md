# Smart contracts for Nalnda Marketplace

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

### Deploy contracts:

Step 1: Update the NALNDA_ERC20 in the .env file.

Step 2: Run command:

```shell
npx hardhat run scripts/deployContracts.js --network <BLOCKCHAIN_NETWORK>
```

### Deploy a new Nalnda ERC20 test token:

```shell
npx hardhat run scripts/deployNalndaToken.js --network <BLOCKCHAIN_NETWORK>
```
