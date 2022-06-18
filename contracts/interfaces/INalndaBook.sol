// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INalndaBook is IERC721 {
    function uri() external view;

    function coverIdCounter() external view returns (uint256);

    function updateLastSoldPrice(uint256 _tokenId, uint256 _price) external;

    function marketplaceTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function creationTimestamp() external view returns (uint256);

    function secondarySalesTimestamp() external view returns (uint256);

    function ownedAt(uint256 _tokenId) external view returns (uint256);

    function lastSoldPrice(uint256 _tokenId) external view returns (uint256);

    function approved() external view returns (bool);

    function changeApproval(bool _newApproved) external;
}
