// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface INalndaMaster {
    function NALNDA() external view returns (address);

    function owner() external view returns (address);

    function secondarySaleAfterDays() external view returns (uint256);

    function transferAfterDays() external view returns (uint256);

    function ITOMarketplace() external view returns (address);
}
