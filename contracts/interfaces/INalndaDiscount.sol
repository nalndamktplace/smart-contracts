// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface INalndaDiscount {
    function NALNDA() external view returns (address);

    function expiry() external view returns (uint256);

    function getDiscount(address _addr) external view returns (uint256);
}
