// SPDX-License-Identifier: None
pragma solidity 0.8.27;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/NalndaMarketplace.sol";

contract DeployNalndaMarketplace is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PVT_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address purchaseToken = 0xdB899cC0CF97f3CEC81cA0ab72C7a3189E7e4555;
        address owner = 0xc478a3d380d841D89dF37fD21A1481deF863456a;
        address authBookCreator = owner;

        NalndaMarketplace marketplace = new NalndaMarketplace(purchaseToken, owner, authBookCreator);
        console.log("NalndaMarketplace deployed at:", address(marketplace));

        vm.stopBroadcast();
    }
}
