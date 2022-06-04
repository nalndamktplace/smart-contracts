// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NalndaBook.sol";
import "./interfaces/INalndaBook.sol";

//primary sales /lazy minintg will only happen using NALNDA token.
contract NalndaMarketplace is Ownable {
    IERC20 public immutable NALNDA;
    uint256 public immutable protocolMintFee; //primarySalesCommission percentage for primary sale/lazy minting
    address[] public bookAddresses;
    mapping(address => address[]) public authorToBooks;
    uint256 public totalBooksCreated;
    uint256 public lastOrderId;
    uint256 public transferAfterDays;
    uint256 public secondarySaleAfterDays;

    //Events
    event NewBookCreated(
        address indexed _author,
        address _bookAddress,
        string _coverURI,
        uint256 _price
    );

    event RevenueWithdrawn(uint256 _revenueWithdrawn);

    constructor(address _NALNDA) {
        require(
            _NALNDA != address(0),
            "NalndaMarketplace: NALNDA token's address can't be null!"
        );
        NALNDA = IERC20(_NALNDA);
        protocolMintFee = 10; //10%
        transferAfterDays = 21; //21 days
        secondarySaleAfterDays = 21; //21 days
        totalBooksCreated = 0;
        lastOrderId = 0;
    }

    function changeTransferAfterDays(uint256 _days) external onlyOwner {
        transferAfterDays = _days;
    }

    function changeSecondarySaleAfterDays(uint256 _days) external onlyOwner {
        secondarySaleAfterDays = _days;
    }

    function createNewBook(
        address _author,
        string memory _coverURI,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256 _genre
    ) external {
        require(
            _author != address(0),
            "NalndaMarketplace: Author address can't be null!"
        );
        require(
            bytes(_coverURI).length > 0,
            "NalndaMarketplace: Empty string passed as cover URI!"
        );
        require(
            _daysForSecondarySales >= 90 && _daysForSecondarySales <= 150,
            "NalndaMarketplace: Days to secondary sales should be between 90 and 150!"
        );
        require(
            _lang > 0 && _lang <= 100,
            "NalndaMarketplace: Book language tag should be between 1 and 100!"
        );
        require(
            _genre > 0 && _genre <= 60,
            "NalndaMarketplace: Book genre tag should be between 1 and 60!"
        );
        address _addressOutput = address(
            new NalndaBook(
                _author,
                _coverURI,
                _initialPrice,
                _daysForSecondarySales,
                _lang,
                _genre
            )
        );
        bookAddresses.push(_addressOutput);
        authorToBooks[_msgSender()].push(_addressOutput);
        totalBooksCreated++;
        emit NewBookCreated(_author, _addressOutput, _coverURI, _initialPrice);
    }

    function bookToAuthor(address _book) public view returns (address author) {
        author = Ownable(_book).owner();
    }

    function withdrawRevenue() external onlyOwner {
        uint256 balance = getNALNDABalance();
        require(balance != 0, "NalndaMarketplace: Nothing to withdraw!");
        NALNDA.transfer(owner(), balance);
        emit RevenueWithdrawn(balance);
    }

    function getNALNDABalance() public view returns (uint256 bal) {
        bal = NALNDA.balanceOf((address(this)));
    }

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

    function listCover(
        INalndaBook _book,
        uint256 _tokenId,
        uint256 _price
    ) external {
        require(
            Address.isContract(address(_book)) == true,
            "NalndaMarketplace: Invalid book address!"
        );
        require(
            _tokenId <= _book.coverIdCounter(),
            "NalndaMarketplace: Invalid tokenId provided!"
        );
        require(
            _book.ownerOf(_tokenId) == _msgSender(),
            "NalndaMarketplace: Seller should own the NFT to list!"
        );
        require(
            block.timestamp >= _book.secondarySalesTimestamp(),
            "NalndaMarketplace: Listing for this book is disabled by the book owner!"
        );
        require(
            block.timestamp >=
                _book.ownedAt(_tokenId) + secondarySaleAfterDays * 1 days,
            "NalndaMarketplace: Can't list the cover at this time!"
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
    }

    function unlistCover(uint256 _orderId) external {
        require(
            _orderId <= lastOrderId,
            "NalndaMarketplace: Invalid order id!"
        );
        Order memory orderCache = ORDER[_orderId];
        require(
            orderCache.stage == Stage.LISTED,
            "NalndaMarketplace: NFT not yet listed / already sold!"
        );
        require(
            _msgSender() == orderCache.seller,
            "NalndaMarketplace: Only seller can unlist!"
        );
        ORDER[_orderId].stage = Stage.UNLISTED; //to prevent reentrancy
        //return the seller its cover
        orderCache.book.marketplaceTransfer(
            address(this),
            orderCache.seller,
            orderCache.tokenId
        );
    }

    function buyCover(uint256 _orderId) external {
        require(
            _orderId <= lastOrderId,
            "NalndaMarketplace: Invalid order id!"
        );
        Order memory orderCache = ORDER[_orderId];
        require(
            orderCache.stage == Stage.LISTED,
            "NalndaMarketplace: NFT not yet listed / already sold!"
        );
        ORDER[_orderId].stage = Stage.SOLD; //to prevent reentrancy
        NALNDA.transferFrom(_msgSender(), address(this), orderCache.price);
        //send author commision
        uint256 authorShare = (orderCache.price * 10) / 100; //10% for author
        NALNDA.transfer(Ownable(address(orderCache.book)).owner(), authorShare);
        //send seller its share
        uint256 sellerShare = (orderCache.price * 88) / 100; //88% to the seller
        NALNDA.transfer(orderCache.seller, sellerShare);
        //update last sold price
        orderCache.book.updateLastSoldPrice(
            orderCache.tokenId,
            orderCache.price
        );
        //transfer NFT to the buyer
        orderCache.book.marketplaceTransfer(
            address(this),
            _msgSender(),
            orderCache.tokenId
        );
    }
}
