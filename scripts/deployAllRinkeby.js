const hre = require("hardhat");

async function main() {
    //deploy test nalnda token
    const Nalnda = await hre.ethers.getContractFactory("Nalnda");
    const nalnda = await Nalnda.deploy();
    await nalnda.deployed();
    console.log("Nalnda ERC20 deployed to:", nalnda.address);
    //deploy NalndaBooksPrimarySales
    const NalndaBooksPrimarySales = await hre.ethers.getContractFactory("NalndaBooksPrimarySales");
    const primarySales = await NalndaBooksPrimarySales.deploy(nalnda.address);
    await primarySales.deployed();
    console.log("NalndaBooksPrimarySales deployed to:", primarySales.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
