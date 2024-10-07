import hre from "hardhat";
import { ethers } from "hardhat";
async function main() {
  const Contract = await ethers.getContractFactory("MockUSDT");
  const contract = await Contract.deploy();
  await contract.deployed();
  console.log("Contract deployed to:", contract.address);
  await contract.deployTransaction.wait(6);
  await hre.run("verify:verify", {
    address: contract.address,
    constructorArguments: [],
  });
}
main();
