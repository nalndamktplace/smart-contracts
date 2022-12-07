const hre = require("hardhat");
require("dotenv").config();

async function main() {
    console.log("Using Nalnda ERC20 deployed to:", process.env.NALNDA_ERC20_HEDERA);
    //deploy NalndaBooksPrimarySales
    const NalndaBooksPrimarySales = await hre.ethers.getContractFactory("NalndaBooksPrimarySales");
    const primarySales = await NalndaBooksPrimarySales.deploy(process.env.NALNDA_ERC20_HEDERA);
    await primarySales.deployed();
    console.log("NalndaBooksPrimarySales deployed to:", primarySales.address);
    const NalndaBooksSecondarySales = await hre.ethers.getContractFactory("NalndaBooksSecondarySales");
    const secondarySales = await NalndaBooksSecondarySales.deploy(process.env.NALNDA_ERC20_HEDERA);
    await secondarySales.deployed();
    console.log("NalndaBooksSecondarySales deployed to:", secondarySales.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
