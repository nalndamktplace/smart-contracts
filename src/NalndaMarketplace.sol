// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./NalndaBook.sol";
import "./NalndaDiscounts.sol";
import "./tokens/NalndaToken.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract NalndaMarketplace is Ownable {
    IERC20 public purchaseToken;
    NalndaToken public immutable nalndaToken;
    NalndaDiscounts public immutable nalndaDiscounts;
    NalndaAirdrop public nalndaAirdrop;

    mapping(address => address[]) public authorToBooks;

    uint256 public totalBooksCreated;
    uint256 public lastOrderId;
    uint256 public transferAfterDays;
    uint256 public secondarySaleAfterDays;
    bool public publicBookCreationAllowed;

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
        NalndaBook book;
        uint256 tokenId;
        uint256 price;
    }

    mapping(uint256 => Order) public ORDER;

    mapping(address => bool) public createdBooks;

    event NewBookCreated(
        address indexed _author, address _bookAddress, string _coverURI, uint256 _price, uint256 _lang, uint256[] _genre
    );
    event CoverListed(
        uint256 indexed _orderId, address _lister, address indexed _book, uint256 indexed _tokenId, uint256 _price
    );
    event CoverUnlisted(
        uint256 indexed _orderId, address indexed _book, uint256 indexed _tokenId, Stage _unlistedStage
    );
    event CoverBought(
        uint256 indexed _orderId, address indexed _book, uint256 indexed _tokenId, address _buyer, uint256 _price
    );
    event RevenueWithdrawn(uint256 _revenueWithdrawn);

    NalndaBook public immutable book_implementation;
    uint256 public immutable chainId;
    uint256 private extraSalt;

    address public authorizedBookCreator;

    function setAuthorizedBookCreator(address _newCreator) external onlyOwner {
        authorizedBookCreator = _newCreator;
    }

    function publicCreationAllowed() private view {
        if (publicBookCreationAllowed == true) {
            return;
        }
        require(
            _msgSender() == authorizedBookCreator, "NalndaMarketplace: Only authorized book creator can create books!"
        );
    }

    function allowPublicBookCreation() external onlyOwner {
        publicBookCreationAllowed = true;
    }

    function changePurchaseToken(address _newToken) external onlyOwner {
        require(_newToken != address(0), "NalndaMarketplace: PurchaseToken token's address can't be null!");
        purchaseToken = IERC20(_newToken);
    }

    constructor(address _purchaseToken, address _initOwner, address _authBookCreator) Ownable(_initOwner) {
        require(_purchaseToken != address(0), "NalndaMarketplace: PurchaseToken token's address can't be null!");
        publicBookCreationAllowed = false;
        purchaseToken = IERC20(_purchaseToken);
        transferAfterDays = 21; //21 days
        secondarySaleAfterDays = 21; //user should have owned cover for at least 21 days
        totalBooksCreated = 0;
        lastOrderId = 0;
        extraSalt = 0;
        uint256 _chainid;
        assembly {
            _chainid := chainid()
        }
        chainId = _chainid;
        book_implementation = new NalndaBook(address(this));
        nalndaAirdrop = new NalndaAirdrop(_initOwner, address(this));
        nalndaDiscounts = new NalndaDiscounts(_initOwner, address(this));
        nalndaToken = nalndaAirdrop.nalndaToken();
        authorizedBookCreator = _authBookCreator;
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
        uint256[] memory _genre
    ) external returns (address _createdBook) {
        publicCreationAllowed();
        return _createNewBook(_author, _coverURI, _initialPrice, _daysForSecondarySales, _lang, _genre);
    }

    function createNewBooks(
        address[] memory _author,
        string[] memory _coverURI,
        uint256[] memory _initialPrice,
        uint256[] memory _daysForSecondarySales,
        uint256[] memory _lang,
        uint256[][] memory _genre
    ) external returns (address[] memory) {
        publicCreationAllowed();
        require(
            _author.length == _coverURI.length && _coverURI.length == _initialPrice.length
                && _initialPrice.length == _daysForSecondarySales.length && _daysForSecondarySales.length == _lang.length
                && _lang.length == _genre.length,
            "NalndaMarketplace: Array lengths should be equal!"
        );
        address[] memory _createdBooks = new address[](_author.length);
        for (uint256 i = 0; i < _author.length; i++) {
            _createdBooks[i] = _createNewBook(
                _author[i], _coverURI[i], _initialPrice[i], _daysForSecondarySales[i], _lang[i], _genre[i]
            );
        }
        return _createdBooks;
    }

    function _createNewBook(
        address _author,
        string memory _coverURI,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre
    ) private returns (address _createdBook) {
        require(_author != address(0), "NalndaMarketplace: Author address can't be null!");
        require(bytes(_coverURI).length > 0, "NalndaMarketplace: Empty string passed as cover URI!");
        //require(
        //    _daysForSecondarySales >= 90 && _daysForSecondarySales <= 150,
        //    "NalndaMarketplace: Days to secondary sales should be between 90 and 150!"
        //);
        require(_lang >= 0 && _lang < 100, "NalndaMarketplace: Book language tag should be between 1 and 100!");
        for (uint256 i = 0; i < _genre.length; i++) {
            require(_genre[i] >= 0 && _genre[i] < 100, "NalndaMarketplace: Book genre tag should be between 1 and 60!");
        }
        address _addressOutput =
            _deployBookProxy(_author, _coverURI, _initialPrice, _daysForSecondarySales, _lang, _genre);
        authorToBooks[_msgSender()].push(_addressOutput);
        totalBooksCreated++;
        createdBooks[_addressOutput] = true;
        emit NewBookCreated(_author, _addressOutput, _coverURI, _initialPrice, _lang, _genre);
        return _addressOutput;
    }

    function _deployBookProxy(
        address _author,
        string memory _coverURI,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre
    ) private returns (address _deployedProxy) {
        extraSalt = extraSalt + 1;
        uint256 salt = uint256(
            keccak256(
                abi.encodePacked(
                    chainId, address(this), _author, _coverURI, _initialPrice, _lang, _genre.length, extraSalt
                )
            )
        );
        _deployedProxy = address(
            NalndaBook(
                payable(
                    new ERC1967Proxy{salt: bytes32(salt)}(
                        address(book_implementation),
                        abi.encodeCall(
                            NalndaBook.initialize,
                            (_author, _coverURI, _initialPrice, _daysForSecondarySales, _lang, _genre, nalndaAirdrop)
                        )
                    )
                )
            )
        );
    }

    function computeNextBookAddress(
        address _author,
        string memory _coverURI,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre
    ) public view returns (address _estimatedAddress) {
        _estimatedAddress =
            _computeBookAddress(_author, _coverURI, _initialPrice, _daysForSecondarySales, _lang, _genre, extraSalt + 1);
    }

    function computeNextBooksAddresses(
        address[] memory _author,
        string[] memory _coverURI,
        uint256[] memory _initialPrice,
        uint256[] memory _daysForSecondarySales,
        uint256[] memory _lang,
        uint256[][] memory _genre
    ) public view returns (address[] memory) {
        uint256 _extraSalt = extraSalt;
        address[] memory _estimatedAddresses = new address[](_author.length);
        require(
            _author.length == _coverURI.length && _coverURI.length == _initialPrice.length
                && _initialPrice.length == _daysForSecondarySales.length && _daysForSecondarySales.length == _lang.length
                && _lang.length == _genre.length,
            "NalndaMarketplace: Array lengths should be equal!"
        );
        for (uint256 i = 0; i < _author.length; i++) {
            _estimatedAddresses[i] = _computeBookAddress(
                _author[i],
                _coverURI[i],
                _initialPrice[i],
                _daysForSecondarySales[i],
                _lang[i],
                _genre[i],
                _extraSalt + i + 1
            );
        }
        return _estimatedAddresses;
    }

    function _computeBookAddress(
        address _author,
        string memory _coverURI,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre,
        uint256 _extraSalt
    ) private view returns (address _estimatedAddress) {
        uint256 salt = uint256(
            keccak256(
                abi.encodePacked(
                    chainId, address(this), _author, _coverURI, _initialPrice, _lang, _genre.length, _extraSalt
                )
            )
        );

        _estimatedAddress = Create2.computeAddress(
            bytes32(salt),
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        address(book_implementation),
                        abi.encodeCall(
                            NalndaBook.initialize,
                            (_author, _coverURI, _initialPrice, _daysForSecondarySales, _lang, _genre, nalndaAirdrop)
                        )
                    )
                )
            )
        );
    }

    function approveBooks(address[] memory _books) public onlyOwner {
        for (uint256 i = 0; i < _books.length; i++) {
            NalndaBook(_books[i]).changeApproval(true);
        }
    }

    function unapproveBooks(address[] memory _books) external onlyOwner {
        for (uint256 i = 0; i < _books.length; i++) {
            NalndaBook(_books[i]).changeApproval(false);
        }
    }

    function bookOwner(address _book) public view returns (address author) {
        author = Ownable(_book).owner();
    }

    function withdrawRevenue() external onlyOwner {
        uint256 balance = getNALNDABalance();
        require(balance != 0, "NalndaMarketplace: Nothing to withdraw!");
        purchaseToken.transfer(owner(), balance);
        emit RevenueWithdrawn(balance);
    }

    function getNALNDABalance() public view returns (uint256 bal) {
        bal = purchaseToken.balanceOf((address(this)));
    }

    function listCover(NalndaBook _book, uint256 _tokenId, uint256 _price) external {
        //require(Address.isContract(address(_book)) == true, "NalndaMarketplace: Invalid book address!");
        require(_tokenId <= _book.coverIdCounter(), "NalndaMarketplace: Invalid tokenId provided!");
        require(_book.ownerOf(_tokenId) == _msgSender(), "NalndaMarketplace: Seller should own the NFT to list!");
        //require(
        //    block.timestamp >= _book.secondarySalesTimestamp(),
        //    "NalndaMarketplace: Listing for this book is disabled!"
        //);
        //require(
        //    block.timestamp >= _book.ownedAt(_tokenId) + secondarySaleAfterDays * 1 days,
        //    "NalndaMarketplace: Can't list the cover at this time!"
        //);
        _book.marketplaceTransfer(_msgSender(), address(this), _tokenId);
        lastOrderId++;
        ORDER[lastOrderId] = Order(Stage.LISTED, lastOrderId, _msgSender(), _book, _tokenId, _price);
        emit CoverListed(lastOrderId, _msgSender(), address(_book), _tokenId, _price);
    }

    function unlistCover(uint256 _orderId) external {
        require(_orderId <= lastOrderId, "NalndaMarketplace: Invalid order id!");
        require(ORDER[_orderId].stage == Stage.LISTED, "NalndaMarketplace: NFT not yet listed / already sold!");
        require(
            _msgSender() == ORDER[_orderId].seller || _msgSender() == owner(),
            "NalndaMarketplace: Only seller or marketplace admin can unlist!"
        );
        _msgSender() == ORDER[_orderId].seller
            ? ORDER[_orderId].stage = Stage.UNLISTED
            : ORDER[_orderId].stage = Stage.UNLISTED_BY_ADMIN;
        //return the seller its cover
        ORDER[_orderId].book.marketplaceTransfer(address(this), ORDER[_orderId].seller, ORDER[_orderId].tokenId);
        emit CoverUnlisted(
            ORDER[_orderId].orderId, address(ORDER[_orderId].book), ORDER[_orderId].tokenId, ORDER[_orderId].stage
        );
    }

    function buyCover(uint256 _orderId) external {
        require(_orderId <= lastOrderId, "NalndaMarketplace: Invalid order id!");
        require(ORDER[_orderId].book.approved() == true, "NalndaMarketplace: Sales on this book are disabled!");
        require(ORDER[_orderId].stage == Stage.LISTED, "NalndaMarketplace: NFT not yet listed / already sold!");
        ORDER[_orderId].stage = Stage.SOLD; //to prevent reentrancy
        purchaseToken.transferFrom(_msgSender(), address(this), ORDER[_orderId].price);
        //send author commision
        uint256 authorShare = (ORDER[_orderId].price * 10) / 100; //10% for author
        purchaseToken.transfer(Ownable(address(ORDER[_orderId].book)).owner(), authorShare);
        //send seller its share
        uint256 sellerShare = (ORDER[_orderId].price * 88) / 100; //88% to the seller
        purchaseToken.transfer(ORDER[_orderId].seller, sellerShare);
        //update last sold price
        ORDER[_orderId].book.updateLastSoldPrice(ORDER[_orderId].tokenId, ORDER[_orderId].price);
        //transfer NFT to the buyer
        ORDER[_orderId].book.marketplaceTransfer(address(this), _msgSender(), ORDER[_orderId].tokenId);
        emit CoverBought(
            ORDER[_orderId].orderId,
            address(ORDER[_orderId].book),
            ORDER[_orderId].tokenId,
            _msgSender(),
            ORDER[_orderId].price
        );
    }
}
