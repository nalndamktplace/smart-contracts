// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.36;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./NalndaBook.sol";

contract NalndaMarketplace is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    mapping(address => address[]) public authorToBooks;

    uint256 public totalBooksCreated;
    uint256 public lastOrderId;
    uint256 public transferAfterDays;
    uint256 public secondarySaleAfterDays;

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
        address indexed _author, address _bookAddress, string _coverUri, uint256 _price, uint256 _lang, uint256[] _genre
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
    address public signerAddress;

    mapping(bytes32 => bool) public executed;

    function setAuthorizedBookCreator(address _newCreator) external onlyOwner {
        authorizedBookCreator = _newCreator;
    }

    constructor(address _initOwner, address _authBookCreator, address _signer) Ownable(_initOwner) {
        //transferAfterDays = 21; //21 days
        transferAfterDays = 0;
        //secondarySaleAfterDays = 21; //user should have owned cover for at least 21 days
        secondarySaleAfterDays = 0;
        totalBooksCreated = 0;
        lastOrderId = 0;
        extraSalt = 0;
        uint256 _chainid;
        assembly {
            _chainid := chainid()
        }
        chainId = _chainid;
        book_implementation = new NalndaBook(address(this));
        authorizedBookCreator = _authBookCreator;
        signerAddress = _signer;
    }

    function getHash(uint256 _nonce) public view returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(address(this), chainId, _nonce));
    }

    function verifySignature(bytes calldata _sig, uint256 _nonce) public view returns (bool isValid) {
        bytes32 ethSignedHash = getHash(_nonce).toEthSignedMessageHash();
        isValid = (signerAddress == ethSignedHash.recover(_sig));
    }

    function setSignerAddress(address _newSignerAddress) external onlyOwner {
        signerAddress = _newSignerAddress;
    }

    function changeTransferAfterDays(uint256 _days) external onlyOwner {
        transferAfterDays = _days;
    }

    function changeSecondarySaleAfterDays(uint256 _days) external onlyOwner {
        secondarySaleAfterDays = _days;
    }

    function createNewBook(
        address _author,
        string memory _coverUri,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre,
        uint256 _nonce,
        bytes calldata signature
    ) external returns (address _createdBook) {
        bytes32 hash = getHash(_nonce);
        require(!executed[hash], "NalndaMarketplace: Hash has already been used!");
        require(verifySignature(signature, _nonce), "NalndaMarketplace: Invalid signature!");
        executed[hash] = true;
        return _createNewBook(_author, _coverUri, _initialPrice, _daysForSecondarySales, _lang, _genre);
    }

    function createNewBooks(
        address[] memory _author,
        string[] memory _coverUri,
        uint256[] memory _initialPrice,
        uint256[] memory _daysForSecondarySales,
        uint256[] memory _lang,
        uint256[][] memory _genre,
        uint256 _nonce,
        bytes calldata signature
    ) external returns (address[] memory) {
        require(
            _author.length == _coverUri.length && _coverUri.length == _initialPrice.length
                && _initialPrice.length == _daysForSecondarySales.length
                && _daysForSecondarySales.length == _lang.length && _lang.length == _genre.length,
            "NalndaMarketplace: Array lengths should be equal!"
        );
        bytes32 hash = getHash(_nonce);
        require(!executed[hash], "NalndaMarketplace: Hash has already been used!");
        require(verifySignature(signature, _nonce), "NalndaMarketplace: Invalid signature!");
        executed[hash] = true;
        address[] memory _createdBooks = new address[](_author.length);
        for (uint256 i = 0; i < _author.length; i++) {
            _createdBooks[i] = _createNewBook(
                _author[i], _coverUri[i], _initialPrice[i], _daysForSecondarySales[i], _lang[i], _genre[i]
            );
        }
        return _createdBooks;
    }

    function _createNewBook(
        address _author,
        string memory _coverUri,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre
    ) private returns (address _createdBook) {
        require(_author != address(0), "NalndaMarketplace: Author address can't be null!");
        require(bytes(_coverUri).length > 0, "NalndaMarketplace: Empty string passed as cover URI!");
        //require(
        //    _daysForSecondarySales >= 90 && _daysForSecondarySales <= 150,
        //    "NalndaMarketplace: Days to secondary sales should be between 90 and 150!"
        //);
        require(_lang >= 0 && _lang < 100, "NalndaMarketplace: Book language tag should be between 1 and 100!");
        for (uint256 i = 0; i < _genre.length; i++) {
            require(_genre[i] >= 0 && _genre[i] < 100, "NalndaMarketplace: Book genre tag should be between 1 and 60!");
        }
        address _addressOutput =
            _deployBookProxy(_author, _coverUri, _initialPrice, _daysForSecondarySales, _lang, _genre);
        authorToBooks[_msgSender()].push(_addressOutput);
        totalBooksCreated++;
        createdBooks[_addressOutput] = true;
        emit NewBookCreated(_author, _addressOutput, _coverUri, _initialPrice, _lang, _genre);
        return _addressOutput;
    }

    function _deployBookProxy(
        address _author,
        string memory _coverUri,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre
    ) private returns (address _deployedProxy) {
        extraSalt = extraSalt + 1;
        uint256 salt = uint256(
            keccak256(
                abi.encodePacked(
                    chainId, address(this), _author, _coverUri, _initialPrice, _lang, _genre.length, extraSalt
                )
            )
        );
        _deployedProxy = address(
            NalndaBook(
                payable(new ERC1967Proxy{salt: bytes32(salt)}(
                        address(book_implementation),
                        abi.encodeCall(
                            NalndaBook.initialize,
                            (_author, _coverUri, _initialPrice, _daysForSecondarySales, _lang, _genre)
                        )
                    ))
            )
        );
    }

    function computeNextBookAddress(
        address _author,
        string memory _coverUri,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre
    ) public view returns (address _estimatedAddress) {
        _estimatedAddress = _computeBookAddress(
            _author, _coverUri, _initialPrice, _daysForSecondarySales, _lang, _genre, extraSalt + 1
        );
    }

    function computeNextBooksAddresses(
        address[] memory _author,
        string[] memory _coverUri,
        uint256[] memory _initialPrice,
        uint256[] memory _daysForSecondarySales,
        uint256[] memory _lang,
        uint256[][] memory _genre
    ) public view returns (address[] memory) {
        uint256 _extraSalt = extraSalt;
        address[] memory _estimatedAddresses = new address[](_author.length);
        require(
            _author.length == _coverUri.length && _coverUri.length == _initialPrice.length
                && _initialPrice.length == _daysForSecondarySales.length
                && _daysForSecondarySales.length == _lang.length && _lang.length == _genre.length,
            "NalndaMarketplace: Array lengths should be equal!"
        );
        for (uint256 i = 0; i < _author.length; i++) {
            _estimatedAddresses[i] = _computeBookAddress(
                _author[i],
                _coverUri[i],
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
        string memory _coverUri,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre,
        uint256 _extraSalt
    ) private view returns (address _estimatedAddress) {
        uint256 salt = uint256(
            keccak256(
                abi.encodePacked(
                    chainId, address(this), _author, _coverUri, _initialPrice, _lang, _genre.length, _extraSalt
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
                            (_author, _coverUri, _initialPrice, _daysForSecondarySales, _lang, _genre)
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

    function withdrawAnyERC20(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        require(bal != 0, "NalndaMarketplace: Nothing to withdraw!");
        bool success = token.transfer(owner(), bal);
        require(success, "NalndaMarketplace: ERC20 Transfer failed!");
    }

    function withdrawAnyEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance != 0, "NalndaMarketplace: Nothing to withdraw!");
        payable(owner()).transfer(balance);
    }

    function listCover(NalndaBook _book, uint256 _tokenId, uint256 _price, uint256 _nonce, bytes calldata signature)
        external
    {
        //require(Address.isContract(address(_book)) == true, "NalndaMarketplace: Invalid book address!");
        require(_tokenId <= _book.coverIdCounter(), "NalndaMarketplace: Invalid tokenId provided!");
        require(_book.ownerOf(_tokenId) == _msgSender(), "NalndaMarketplace: Seller should own the NFT to list!");
        //require(
        //    block.timestamp >= _book.secondarySalesTimestamp(),
        //    "NalndaMarketplace: Listing for this book is disabled!"
        //);
        require(
            block.timestamp >= _book.ownedAt(_tokenId) + secondarySaleAfterDays * 1 days,
            "NalndaMarketplace: Can't list the cover at this time!"
        );
        bytes32 hash = getHash(_nonce);
        require(!executed[hash], "NalndaMarketplace: Hash has already been used!");
        require(verifySignature(signature, _nonce), "NalndaMarketplace: Invalid signature!");
        executed[hash] = true;
        _book.marketplaceTransfer(_msgSender(), address(this), _tokenId);
        lastOrderId++;
        ORDER[lastOrderId] = Order({
            stage: Stage.LISTED,
            orderId: lastOrderId,
            seller: _msgSender(),
            book: _book,
            tokenId: _tokenId,
            price: _price
        });
        emit CoverListed(lastOrderId, _msgSender(), address(_book), _tokenId, _price);
    }

    function unlistCover(uint256 _orderId, uint256 _nonce, bytes calldata signature) external {
        require(_orderId <= lastOrderId, "NalndaMarketplace: Invalid order id!");
        require(ORDER[_orderId].stage == Stage.LISTED, "NalndaMarketplace: NFT not yet listed / already sold!");
        require(
            _msgSender() == ORDER[_orderId].seller || _msgSender() == owner(),
            "NalndaMarketplace: Only seller or marketplace admin can unlist!"
        );
        bytes32 hash = getHash(_nonce);
        require(!executed[hash], "NalndaMarketplace: Hash has already been used!");
        require(verifySignature(signature, _nonce), "NalndaMarketplace: Invalid signature!");
        executed[hash] = true;
        _msgSender() == ORDER[_orderId].seller
            ? ORDER[_orderId].stage = Stage.UNLISTED
            : ORDER[_orderId].stage = Stage.UNLISTED_BY_ADMIN;
        //return the seller its cover
        ORDER[_orderId].book.marketplaceTransfer(address(this), ORDER[_orderId].seller, ORDER[_orderId].tokenId);
        emit CoverUnlisted(
            ORDER[_orderId].orderId, address(ORDER[_orderId].book), ORDER[_orderId].tokenId, ORDER[_orderId].stage
        );
    }

    function buyCover(uint256 _orderId, uint256 _nonce, bytes calldata signature) external {
        require(_orderId <= lastOrderId, "NalndaMarketplace: Invalid order id!");
        require(ORDER[_orderId].book.approved() == true, "NalndaMarketplace: Sales on this book are disabled!");
        require(ORDER[_orderId].stage == Stage.LISTED, "NalndaMarketplace: NFT not yet listed / already sold!");
        bytes32 hash = getHash(_nonce);
        require(!executed[hash], "NalndaMarketplace: Hash has already been used!");
        require(verifySignature(signature, _nonce), "NalndaMarketplace: Invalid signature!");
        executed[hash] = true;
        ORDER[_orderId].stage = Stage.SOLD; //to prevent reentrancy
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
