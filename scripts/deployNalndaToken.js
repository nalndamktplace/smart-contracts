const hre = require("hardhat");
require("dotenv").config();

async function main() {
    //deploy test nalnda token
    const Nalnda = await hre.ethers.getContractFactory("Nalnda");
    const nalnda = await Nalnda.deploy();
    await nalnda.deployed();
    console.log("Nalnda token deployed to: ", nalnda.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
