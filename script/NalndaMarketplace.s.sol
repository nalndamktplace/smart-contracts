// SPDX-License-Identifier: None
pragma solidity 0.8.36;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/NalndaMarketplace.sol";
import "../src/NalndaSCWFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployNalndaMarketplace is Script {
    IEntryPoint private constant ENTRY_POINT = IEntryPoint(0x0000000071727De22E5E9d8BAf0edAc6f37da032);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PVT_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = 0xc478a3d380d841D89dF37fD21A1481deF863456a;
        address signer = 0xc478a3d380d841D89dF37fD21A1481deF863456a;
        address trustedForwarder = address(0); // ERC-2771 disabled; ERC-4337 does not need a trusted forwarder.

        NalndaMarketplace implementation = new NalndaMarketplace();
        NalndaMarketplace marketplace = NalndaMarketplace(
            payable(address(
                    new ERC1967Proxy(
                        address(implementation),
                        abi.encodeCall(NalndaMarketplace.initialize, (owner, signer, trustedForwarder))
                    )
                ))
        );
        NalndaSCWFactory scwFactory = new NalndaSCWFactory(ENTRY_POINT);

        console.log("NalndaMarketplace implementation deployed at:", address(implementation));
        console.log("NalndaMarketplace deployed at:", address(marketplace));
        console.log("NalndaSCW implementation deployed at:", address(scwFactory.accountImplementation()));
        console.log("NalndaSCWFactory deployed at:", address(scwFactory));

        vm.stopBroadcast();
    }
}
