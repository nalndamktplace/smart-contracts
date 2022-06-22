// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INalndaITOBook is IERC721 {
    function uri() external view;

    function coverIdCounter() external view returns (uint256);

    function updateLastSoldPrice(uint256 _tokenId, uint256 _price) external;

    function marketplaceTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function secondarySalesTimestamp() external view returns (uint256);

    function ownedAt(uint256 _tokenId) external view returns (uint256);

    function lastSoldPrice(uint256 _tokenId) external view returns (uint256);

    function startNormalSalesTransfers() external view returns (bool);

    function approveBookStartITO(address[] memory _approvedAddresses) external;

    function addMoreApprovedAddresses(address[] memory _approvedAddresses)
        external;
}
