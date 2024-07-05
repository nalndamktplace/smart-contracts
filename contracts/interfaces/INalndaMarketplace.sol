// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface INalndaMarketplace {
    enum AirdropSlab {
        None,
        ZeroToFiveK,
        FiveK1ToTenK,
        TenK1ToTwentyK,
        TwentyK1ToThirtyK,
        ThirtyK1ToFiftyK
    }

    function purchaseToken() external view returns (address);

    function transferAfterDays() external view returns (uint256);

    function totalBooksCreated() external view returns (uint256);
}
