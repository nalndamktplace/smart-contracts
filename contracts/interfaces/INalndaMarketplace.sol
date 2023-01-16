// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INalndaMarketplace {
    function NALNDA() external view returns (address);

    function transferAfterDays() external view returns (uint256);

    function owner() external view returns (address);
}
