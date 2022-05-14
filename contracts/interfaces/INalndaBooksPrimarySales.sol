// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface INalndaBooksPrimarySales {
    function NALNDA() external view returns (address);

    function commissionPercent() external view returns (uint256);

    function createNewBook(
        address _author,
        string memory _coverURI,
        uint256 _initialPrice
    ) external;
}
