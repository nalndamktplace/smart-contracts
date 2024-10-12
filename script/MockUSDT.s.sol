// SPDX-License-Identifier: None
pragma solidity 0.8.27;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/tokens/mockUSDT.sol";

contract DeployMockUSDT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PVT_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MockUSDT usdt = new MockUSDT();
        console.log("MockUSDT deployed at:", address(usdt));

        vm.stopBroadcast();
    }
}
