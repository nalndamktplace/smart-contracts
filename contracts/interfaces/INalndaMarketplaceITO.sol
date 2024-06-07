// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface INalndaMarketplaceITO {
    function NALNDA() external view returns (address);

    function transferAfterDays() external view returns (uint256);
}
