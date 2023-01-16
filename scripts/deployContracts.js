require("dotenv").config();
const hre = require("hardhat");
const fs = require('fs')

async function main() {
    const usdc_nalnda = process.env.NALNDA_ERC20;
    console.log("Using Nalnda ERC20 deployed to:", usdc_nalnda);
    //deploy NalndaBooksPrimarySales
    const NalndaMarketplace = await hre.ethers.getContractFactory("NalndaMarketplace");
    const marketplace = await NalndaMarketplace.deploy(usdc_nalnda);
    await marketplace.deployed();
    console.log("NalndaMarketplace deployed to:", marketplace.address);
    const toStore = {
        'NALNDA_USDC': usdc_nalnda.toString(),
        'NalndaMarketplace': marketplace.address.toString()
    }
    const toStoreStringified = JSON.stringify(toStore);
    fs.writeFileSync("./latest_addresses.json", toStoreStringified, function (err, result) {
        if (err) console.log('error', err);
    });
    console.log("done...");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
