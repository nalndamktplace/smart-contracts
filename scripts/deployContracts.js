const hre = require("hardhat");
require("dotenv").config();

async function main() {
    console.log("Using Nalnda ERC20 deployed to:", process.env.NALNDA_ERC20);
    //deploy NalndaBooksPrimarySales
    const NalndaMarketplace = await hre.ethers.getContractFactory("NalndaMarketplace");
    const marketplace = await NalndaMarketplace.deploy(process.env.NALNDA_ERC20);
    await marketplace.deployed();
    console.log("NalndaMarketplace deployed to:", marketplace.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
