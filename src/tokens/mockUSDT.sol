// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockUSDT is ERC20 {
    constructor() ERC20("Mock USDT", "mockUSDT") {}

    function mint(uint256 amount) public {
        _mint(_msgSender(), amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
