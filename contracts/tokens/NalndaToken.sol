// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NalndaToken is ERC20 {
    constructor(address _airdropContract) ERC20("Nalnda Token", "NALNDA") {
        uint256 _totalPremint = 500000000 * 10 ** decimals(); // 500M
        uint256 _airdropPremint = 13500000 * 10 ** decimals(); // 13.5M
        _mint(_airdropContract, _airdropPremint);
        uint256 _remainingPremint = _totalPremint - _airdropPremint;
        // todo: decide where the remaining amount go
        _mint(msg.sender, _remainingPremint);
    }
}
