// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/INalndaBook.sol";

//all purschases and listing is done using NALANDA tokens only, for now.
contract NalndaBooksSecondarySales is Ownable {
    IERC20 public immutable NALNDA;
    uint256 public immutable platformFee;
    uint256 public immutable authorCommision;
    uint256 public lastId;

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

    //events
    event CoverListed(
        uint256 indexed _orderId,
        address _lister,
        address indexed _book,
        uint256 indexed _tokenId,
        uint256 _price
    );

    event CoverUnlisted(
        uint256 indexed _orderId,
        address indexed _book,
        uint256 indexed _tokenId
    );
    event CoverBought(
        uint256 indexed _orderId,
        address indexed _book,
        uint256 indexed _tokenId,
        address _buyer,
        uint256 _price
    );

    event RevenueWithdrawn(uint256 _revenueWithdrawn);

    constructor(address _NALNDA) {
        require(
            _NALNDA != address(0),
            "NalndaBooksSecondarySales: NALNDA token's address can't be null!"
        );
        NALNDA = IERC20(_NALNDA);
        platformFee = 2; //2%
        authorCommision = 10; //10%
        lastId = 0;
    }

    function listCover(
        INalndaBook _book,
        uint256 _tokenId,
        uint256 _price
    ) external {
        require(
            Address.isContract(address(_book)) == true,
            "NalndaBooksSecondarySales: Invalid book address!"
        );
        require(
            _tokenId <= _book.coverIdCounter(),
            "NalndaBooksSecondarySales: Invalid tokenId provided!"
        );
        require(
            _book.ownerOf(_tokenId) == _msgSender(),
            "NalndaBooksSecondarySales: Seller should own the NFT to list!"
        );
        _book.transferFrom(_msgSender(), address(this), _tokenId);
        lastId++;
        ORDER[lastId] = Order(
            Stage.LISTED,
            lastId,
            _msgSender(),
            _book,
            _tokenId,
            _price
        );
        emit CoverListed(
            lastId,
            _msgSender(),
            address(_book),
            _tokenId,
            _price
        );
    }

    function unlistCover(uint256 _orderId) external {
        require(
            _orderId <= lastId,
            "NalndaBooksSecondarySales: Invalid order id!"
        );
        Order memory orderCache = ORDER[_orderId];
        require(
            orderCache.stage == Stage.LISTED,
            "NalndaBooksSecondarySales: NFT not yet listed / already sold!"
        );
        require(
            _msgSender() == orderCache.seller,
            "NalndaBooksSecondarySales: Only seller can unlist!"
        );
        ORDER[_orderId].stage = Stage.UNLISTED; //to prevent reentrancy
        //return the seller its cover
        orderCache.book.safeTransferFrom(
            address(this),
            orderCache.seller,
            orderCache.tokenId
        );
        emit CoverUnlisted(
            orderCache.orderId,
            address(orderCache.book),
            orderCache.tokenId
        );
    }

    function buyCover(uint256 _orderId) external {
        require(
            _orderId <= lastId,
            "NalndaBooksSecondarySales: Invalid order id!"
        );
        Order memory orderCache = ORDER[_orderId];
        require(
            orderCache.stage == Stage.LISTED,
            "NalndaBooksSecondarySales: NFT not yet listed / already sold!"
        );
        ORDER[_orderId].stage = Stage.SOLD; //to prevent reentrancy
        NALNDA.transferFrom(_msgSender(), address(this), orderCache.price);
        //send author commision
        uint256 authorShare = (orderCache.price * authorCommision) / 100;
        NALNDA.transfer(Ownable(address(orderCache.book)).owner(), authorShare);
        //send seller its share
        uint256 sellerSharePercent = (100 - authorCommision - platformFee);
        uint256 sellerShare = (orderCache.price * sellerSharePercent) / 100;
        NALNDA.transfer(orderCache.seller, sellerShare);
        //transfer NFT to the buyer
        orderCache.book.safeTransferFrom(
            address(this),
            _msgSender(),
            orderCache.tokenId
        );
        emit CoverBought(
            orderCache.orderId,
            address(orderCache.book),
            orderCache.tokenId,
            _msgSender(),
            orderCache.price
        );
    }

    function withdrawRevenue() external onlyOwner {
        uint256 balance = NALNDA.balanceOf(address(this));
        require(
            balance != 0,
            "NalndaBooksSecondarySales: Nothing to withdraw!"
        );
        NALNDA.transfer(owner(), balance);
        emit RevenueWithdrawn(balance);
    }
}
