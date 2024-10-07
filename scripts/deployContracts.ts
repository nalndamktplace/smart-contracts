import hre from "hardhat";
import { ethers } from "hardhat";
async function main() {
  const Contract = await ethers.getContractFactory("NalndaMarketplace");
  const initOwner = "0xc478a3d380d841D89dF37fD21A1481deF863456a";
  console.log("Using purchase token:", process.env.PURCHASE_TOKEN!);
  const contract = await Contract.deploy(
    process.env.PURCHASE_TOKEN!,
    initOwner,
    initOwner
  );
  await contract.deployed();
  console.log("Contract deployed to:", contract.address);
  //await contract.deployTransaction.wait(6);
  //await hre.run("verify:verify", {
  //  address: contract.address,
  //  constructorArguments: [process.env.PURCHASE_TOKEN!, initOwner, initOwner],
  //});
}
main();
