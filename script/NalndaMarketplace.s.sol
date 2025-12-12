// SPDX-License-Identifier: None
pragma solidity 0.8.27;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/NalndaMarketplace.sol";

contract DeployNalndaMarketplace is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PVT_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = 0xc478a3d380d841D89dF37fD21A1481deF863456a;
        address signer = 0xc478a3d380d841D89dF37fD21A1481deF863456a;
        address authBookCreator = owner;

        NalndaMarketplace marketplace = new NalndaMarketplace(owner, authBookCreator, signer);
        console.log("NalndaMarketplace deployed at:", address(marketplace));

        vm.stopBroadcast();
    }
}
