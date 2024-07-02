// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface INalndaMarketplace {
    function purchaseToken() external view returns (address);

    function transferAfterDays() external view returns (uint256);

    function discountContract() external view returns (address);
}
