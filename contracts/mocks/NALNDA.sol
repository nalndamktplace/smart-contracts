// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Nalnda is ERC20 {
    constructor() ERC20("Nalnda", "NALNDA") {
        _mint(msg.sender, 1000 * 10**decimals());
    }
}
