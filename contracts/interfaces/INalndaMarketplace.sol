// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface INalndaMarketplace {
    function NALNDA() external view returns (address);

    function protocolMintFee() external view returns (uint256);

    function transferAfterDays() external view returns (uint256);

    function discountContract() external view returns (address);
}
