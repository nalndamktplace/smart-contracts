// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./tokens/NalndaToken.sol";

contract NalndaAirdrop is Ownable {
    NalndaToken nalndaToken;
    uint256 public immutable maxTokens;

    constructor() {
        nalndaToken = NalndaToken(address(0));
        maxTokens = 13500000 * 10 ** 18; // 13.5M
    }

    modifier contractEnabled() {
        require(address(nalndaToken) != address(0));
        _;
    }

    function initialize(address _nalndaToken) external onlyOwner {
        require(address(nalndaToken) == address(0), "Already initialized!");
        nalndaToken = NalndaToken(_nalndaToken);
        require(NalndaToken(_nalndaToken).balanceOf(address(this)) == maxTokens, "Not enough tokens!");
    }
}
