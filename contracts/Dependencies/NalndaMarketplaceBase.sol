// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/INalndaDiscount.sol";
import "../interfaces/INalndaBook.sol";

abstract contract NalndaMarketplaceBase {
    IERC20 public NALNDA;

    uint256 public protocolMintFee; //primarySalesCommission percentage for primary sale/lazy minting

    address[] public bookAddresses;

    mapping(address => address[]) public authorToBooks;

    uint256 public totalBooksCreated;

    uint256 public lastOrderId;

    uint256 public transferAfterDays;

    uint256 public secondarySaleAfterDays;

    INalndaDiscount public discountContract;

    enum Stage {
        UNLISTED,
        LISTED,
        SOLD
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
