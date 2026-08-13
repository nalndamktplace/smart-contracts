// SPDX-License-Identifier: None
pragma solidity 0.8.36;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/NalndaMarketplace.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployNalndaMarketplace is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PVT_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = 0xc478a3d380d841D89dF37fD21A1481deF863456a;
        address signer = 0xc478a3d380d841D89dF37fD21A1481deF863456a;
        address authBookCreator = owner;
        address trustedForwarder = address(0); // ERC-2771 disabled; ERC-4337 does not need a trusted forwarder.

        NalndaMarketplace implementation = new NalndaMarketplace();
        NalndaMarketplace marketplace = NalndaMarketplace(
            payable(address(
                    new ERC1967Proxy(
                        address(implementation),
                        abi.encodeCall(NalndaMarketplace.initialize, (owner, authBookCreator, signer, trustedForwarder))
                    )
                ))
        );
        console.log("NalndaMarketplace implementation deployed at:", address(implementation));
        console.log("NalndaMarketplace deployed at:", address(marketplace));

        vm.stopBroadcast();
    }
}
