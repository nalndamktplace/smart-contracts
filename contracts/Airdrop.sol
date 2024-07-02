// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./tokens/NalndaToken.sol";

contract NalndaAirdrop is Ownable {
    NalndaToken immutable nalndaToken;
    uint256 public immutable maxTokens = 13500000 * 10 ** 18; // 13.5M

    constructor(address _initOwner) {
        nalndaToken = new NalndaToken(address(this), _initOwner);
        maxTokens = 13500000 * 10 ** 18; // 13.5M
        _transferOwnership(_initOwner);
    }
}
