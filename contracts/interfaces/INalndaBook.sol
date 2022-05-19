// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INalndaBook is IERC721 {
    function uri() external view;

    function coverIdCounter() external view returns (uint256);
}
