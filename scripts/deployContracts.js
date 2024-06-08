const hre = require("hardhat");
require("dotenv").config();

async function main() {
  console.log("Using Nalnda ERC20 deployed to:", process.env.NALNDA_ERC20);
  //deploy NalndaBooksPrimarySales
  const NalndaMarketplace = await hre.ethers.getContractFactory(
    "NalndaMarketplace"
  );
  const marketplace = await NalndaMarketplace.deploy(process.env.NALNDA_ERC20);
  await marketplace.deployed();

  //await hre.run("verify:verify", {
  //  address: marketplace.address,
  //  constructorArguments: [process.env.NALNDA_ERC20],
  //});
  console.log("NalndaMarketplace deployed to:", marketplace.address);
  ////deploying discounts
  //const NalndaDiscountV1 = await hre.ethers.getContractFactory(
  //  "NalndaDiscountV1"
  //);
  //const discount_v1 = await NalndaDiscountV1.deploy(
  //  process.env.NALNDA_ERC20,
  //  marketplace.address,
  //  [],
  //  []
  //);
  //await discount_v1.deployed();
  //console.log("NalndaDiscountV1 deployed to:", discount_v1.address);
  //console.log("setting address for discount contract...");
  //await marketplace.setDiscountContract(discount_v1.address);
  console.log("done...");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
