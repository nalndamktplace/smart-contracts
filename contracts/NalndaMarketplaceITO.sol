// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/INalndaITOBook.sol";
import "./interfaces/INalndaMaster.sol";

//primary sales /lazy minintg will only happen using NALNDA token.
contract NalndaMarketplaceITO is Context {
    INalndaMaster public immutable master;

    IERC20 public immutable NALNDA;

    uint256 public lastOrderId;

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
        INalndaITOBook book;
        uint256 tokenId;
        uint256 price;
    }

    //orderId => Order
    mapping(uint256 => Order) public ORDER;
    //Events
    event NewITOBookCreated(
        address indexed _author,
        address _bookAddress,
        string _coverURI,
        uint256 _price,
        uint256 _lang,
        uint256[] _genre
    );
    event ITOCoverListed(
        uint256 indexed _orderId,
        address _lister,
        address indexed _book,
        uint256 indexed _tokenId,
        uint256 _price
    );
    event ITOCoverUnlisted(
        uint256 indexed _orderId,
        address indexed _book,
        uint256 indexed _tokenId,
        Stage _unlistedStage
    );
    event ITOCoverBought(
        uint256 indexed _orderId,
        address indexed _book,
        uint256 indexed _tokenId,
        address _buyer,
        uint256 _price
    );

    constructor(address _NALNDA) {
        require(
            _NALNDA != address(0),
            "NalndaMarketplaceITO: NALNDA token's address can't be null!"
        );
        NALNDA = IERC20(_NALNDA);
        master = INalndaMaster(_msgSender());
        lastOrderId = 0;
    }

    function listCover(
        INalndaITOBook _book,
        uint256 _tokenId,
        uint256 _price
    ) external {
        require(
            Address.isContract(address(_book)) == true,
            "NalndaMarketplaceITO: Invalid book address!"
        );
        require(
            _tokenId <= _book.coverIdCounter(),
            "NalndaMarketplaceITO: Invalid tokenId provided!"
        );
        require(
            _book.ownerOf(_tokenId) == _msgSender(),
            "NalndaMarketplaceITO: Seller should own the NFT to list!"
        );
        require(
            block.timestamp >= _book.secondarySalesTimestamp(),
            "NalndaMarketplaceITO: Listing for this book is disabled!"
        );
        require(
            block.timestamp >=
                _book.ownedAt(_tokenId) +
                    master.secondarySaleAfterDays() *
                    1 days,
            "NalndaMarketplaceITO: Can't list the cover at this time!"
        );
        _book.marketplaceTransfer(_msgSender(), address(this), _tokenId);
        lastOrderId++;
        ORDER[lastOrderId] = Order(
            Stage.LISTED,
            lastOrderId,
            _msgSender(),
            _book,
            _tokenId,
            _price
        );
        emit ITOCoverListed(
            lastOrderId,
            _msgSender(),
            address(_book),
            _tokenId,
            _price
        );
    }

    function unlistCover(uint256 _orderId) external {
        require(
            _orderId <= lastOrderId,
            "NalndaMarketplaceITO: Invalid order id!"
        );
        require(
            ORDER[_orderId].stage == Stage.LISTED,
            "NalndaMarketplaceITO: NFT not yet listed / already sold!"
        );
        require(
            _msgSender() == ORDER[_orderId].seller ||
                _msgSender() == master.owner(),
            "NalndaMarketplaceITO: Only seller or master admin can unlist!"
        );
        _msgSender() == ORDER[_orderId].seller
            ? ORDER[_orderId].stage = Stage.UNLISTED
            : ORDER[_orderId].stage = Stage.UNLISTED_BY_ADMIN;
        //return the seller its cover
        ORDER[_orderId].book.marketplaceTransfer(
            address(this),
            ORDER[_orderId].seller,
            ORDER[_orderId].tokenId
        );
        emit ITOCoverUnlisted(
            ORDER[_orderId].orderId,
            address(ORDER[_orderId].book),
            ORDER[_orderId].tokenId,
            ORDER[_orderId].stage
        );
    }

    function buyCover(uint256 _orderId) external {
        require(
            _orderId <= lastOrderId,
            "NalndaMarketplaceITO: Invalid order id!"
        );
        require(
            ORDER[_orderId].book.startNormalSalesTransfers() == true,
            "NalndaMarketplaceITO: Sales on this book are disabled!"
        );
        require(
            ORDER[_orderId].stage == Stage.LISTED,
            "NalndaMarketplaceITO: NFT not yet listed / already sold!"
        );
        ORDER[_orderId].stage = Stage.SOLD; //to prevent reentrancy
        NALNDA.transferFrom(_msgSender(), address(this), ORDER[_orderId].price);
        //send seller its share
        uint256 sellerShare = (ORDER[_orderId].price * 88) / 100; //88% to the seller
        NALNDA.transfer(ORDER[_orderId].seller, sellerShare);
        //send protocol its share
        uint256 protocolFee = (ORDER[_orderId].price * 2) / 100; //2% to the master
        NALNDA.transfer(address(master), protocolFee);
        uint256 remaining = (ORDER[_orderId].price * 10) / 100; //remaining 10%
        //send author commision
        uint256 authorShare = (remaining * 70) / 100; //70% of 10% to the book owner
        NALNDA.transfer(
            Ownable(address(ORDER[_orderId].book)).owner(),
            authorShare
        );
        uint256 DOCommissions = (remaining * 30) / 100; //30% of 10% to the DOs
        NALNDA.transfer(address(ORDER[_orderId].book), DOCommissions);
        //update DOCommissions
        ORDER[_orderId].book.increaseTotalDOCommissions(DOCommissions);
        //update last sold price
        ORDER[_orderId].book.updateLastSoldPrice(
            ORDER[_orderId].tokenId,
            ORDER[_orderId].price
        );
        //transfer NFT to the buyer
        ORDER[_orderId].book.marketplaceTransfer(
            address(this),
            _msgSender(),
            ORDER[_orderId].tokenId
        );
        emit ITOCoverBought(
            ORDER[_orderId].orderId,
            address(ORDER[_orderId].book),
            ORDER[_orderId].tokenId,
            _msgSender(),
            ORDER[_orderId].price
        );
    }
}
