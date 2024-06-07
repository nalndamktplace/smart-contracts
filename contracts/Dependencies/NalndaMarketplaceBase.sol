// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/INalndaDiscount.sol";
import "../interfaces/INalndaBook.sol";

abstract contract NalndaMarketplaceBase {
    IERC20 public NALNDA;

    mapping(address => address[]) public authorToBooks;

    uint256 public totalBooksCreated;

    uint256 public lastOrderId;

    uint256 public transferAfterDays;

    uint256 public secondarySaleAfterDays;

    INalndaDiscount public discountContract;

    enum Stage {
        UNLISTED,
        LISTED,
        SOLD,
        UNLISTED_BY_ADMIN
    }

    struct Order {
        Stage stage;
        uint256 orderId;
        address seller;
        INalndaBook book;
        uint256 tokenId;
        uint256 price;
    }

    //orderId => Order
    mapping(uint256 => Order) public ORDER;
}
