const hre = require("hardhat");
require("dotenv").config();

async function main() {
  //deploy test nalnda token
  const Nalnda = await hre.ethers.getContractFactory("Nalnda");
  const nalnda = await Nalnda.deploy();
  await nalnda.deployed();
  const premintAmount = hre.ethers.utils.parseEther("10000000000000");
  const mintTx = await nalnda.mint(premintAmount);
  console.log("Mint txn: ", mintTx.hash);
  console.log("Nalnda token deployed to: ", nalnda.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
