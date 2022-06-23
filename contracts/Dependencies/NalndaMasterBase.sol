// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/INalndaDiscount.sol";
import "../interfaces/INalndaBook.sol";

abstract contract NalndaMasterBase {
    IERC20 public NALNDA;

    mapping(address => address[]) public authorToBooks;

    uint256 public totalBooksCreated;

    uint256 public transferAfterDays;

    uint256 public secondarySaleAfterDays;

    address public ITOMarketplace;
}
