// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface INalndaMarketplaceITO {
    function NALNDA() external view returns (address);

    function transferAfterDays() external view returns (uint256);

    function discountContract() external view returns (address);
}
