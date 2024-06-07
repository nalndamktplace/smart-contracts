// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Nalnda is ERC20, Ownable {
    constructor() ERC20("Nalnda", "NALNDA") {}

    function mint(uint256 amount) public {
        _mint(_msgSender(), amount);
    }
}
