const hre = require("hardhat");
require("dotenv").config();

async function main() {
  //deploy test nalnda token
  //function TetherToken(uint256 _initialSupply, string _name, string _symbol, uint256 _decimals) public {

  const Contract = await hre.ethers.getContractFactory("TetherToken");
  const _initialSupply = hre.ethers.utils.parseEther("100000000000000");
  const nalndaUSDT = await Contract.deploy(
    _initialSupply,
    "nalndaUSDT",
    "nUSDT",
    "6"
  );
  await nalndaUSDT.deployed();
  await nalndaUSDT.deployTransaction.wait(5);
  console.log("Contract deployed to:", nalndaUSDT.address);

  await hre.run("verify:verify", {
    address: nalndaUSDT.address,
    constructorArguments: [_initialSupply, "nalndaUSDT", "nUSDT", "6"],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
