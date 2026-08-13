// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.36;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./NalndaBook.sol";

contract NalndaMarketplace is Ownable, Initializable, UUPSUpgradeable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    error MarketplacePaused();
    error MarketplaceNotPaused();
    error InvalidSignerAddress();
    error InvalidAuthorizedBookCreator();
    error InvalidTrustedForwarder();
    error InvalidTokenAddress();
    error UnknownBook();

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant EIP712_NAME_HASH = keccak256("NalndaMarketplace");
    bytes32 private constant EIP712_VERSION_HASH = keccak256("1");

    bytes32 private constant CREATE_NEW_BOOK_TYPEHASH = keccak256(
        "CreateNewBook(address caller,address author,bytes32 coverUriHash,uint256 initialPrice,uint256 daysForSecondarySales,uint256 lang,bytes32 genreHash,uint256 nonce,uint48 deadline)"
    );
    bytes32 private constant CREATE_NEW_BOOKS_TYPEHASH =
        keccak256("CreateNewBooks(address caller,bytes32 argumentsHash,uint256 nonce,uint48 deadline)");
    bytes32 private constant LIST_COVER_TYPEHASH =
        keccak256("ListCover(address seller,address book,uint256 tokenId,uint256 price,uint256 nonce,uint48 deadline)");
    bytes32 private constant UNLIST_COVER_TYPEHASH =
        keccak256("UnlistCover(address caller,uint256 orderId,uint256 nonce,uint48 deadline)");
    bytes32 private constant BUY_COVER_TYPEHASH =
        keccak256("BuyCover(address buyer,uint256 orderId,uint256 nonce,uint48 deadline)");

    mapping(address => address[]) public authorToBooks;

    uint256 public totalBooksCreated;
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
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event SignerAddressUpdated(address indexed previousSigner, address indexed newSigner);
    event TrustedForwarderUpdated(address indexed previousForwarder, address indexed newForwarder);

    NalndaBook public immutable book_implementation;
    uint256 public immutable chainId;
    uint256 private extraSalt;
    address public authorizedBookCreator;
    address public signerAddress;
    bool public paused;

    mapping(bytes32 => bool) public executed;
    address public trustedForwarder;

    modifier whenNotPaused() {
        if (paused) revert MarketplacePaused();
        _;
    }

    function setAuthorizedBookCreator(address _newCreator) external onlyOwner {
        if (_newCreator == address(0)) revert InvalidAuthorizedBookCreator();
        authorizedBookCreator = _newCreator;
    }

    function pause() external onlyOwner {
        if (paused) revert MarketplacePaused();
        paused = true;
        emit Paused(_msgSender());
    }

    function unpause() external onlyOwner {
        if (!paused) revert MarketplaceNotPaused();
        paused = false;
        emit Unpaused(_msgSender());
    }

    constructor() Ownable(_msgSender()) {
        _disableInitializers();
        uint256 _chainid;
        assembly {
            _chainid := chainid()
        }
        chainId = _chainid;
        book_implementation = new NalndaBook(address(this));
    }

    function initialize(address _initOwner, address _authBookCreator, address _signer, address _trustedForwarder)
        external
        initializer
    {
        if (_initOwner == address(0)) revert OwnableInvalidOwner(address(0));
        if (_signer == address(0)) revert InvalidSignerAddress();
        if (_authBookCreator == address(0)) revert InvalidAuthorizedBookCreator();
        _validateTrustedForwarder(_trustedForwarder);
        _transferOwnership(_initOwner);
        authorizedBookCreator = _authBookCreator;
        signerAddress = _signer;
        trustedForwarder = _trustedForwarder;
    }

    function setTrustedForwarder(address _newTrustedForwarder) external onlyOwner {
        _validateTrustedForwarder(_newTrustedForwarder);
        address previousForwarder = trustedForwarder;
        trustedForwarder = _newTrustedForwarder;
        emit TrustedForwarderUpdated(previousForwarder, _newTrustedForwarder);
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == trustedForwarder;
    }

    function _validateTrustedForwarder(address _trustedForwarder) private view {
        if (_trustedForwarder != address(0) && _trustedForwarder.code.length == 0) {
            revert InvalidTrustedForwarder();
        }
    }

    function _hashTypedData(bytes32 _structHash) private view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, EIP712_NAME_HASH, EIP712_VERSION_HASH, block.chainid, address(this))
        );
        return MessageHashUtils.toTypedDataHash(domainSeparator, _structHash);
    }

    function _authorize(bytes32 _structHash, uint48 _deadline, bytes calldata _signature) private {
        require(block.timestamp <= _deadline, "NalndaMarketplace: Signature expired!");
        bytes32 digest = _hashTypedData(_structHash);
        require(!executed[digest], "NalndaMarketplace: Hash has already been used!");
        require(signerAddress == digest.recover(_signature), "NalndaMarketplace: Invalid signature!");
        executed[digest] = true;
    }

    function setSignerAddress(address _newSignerAddress) external onlyOwner {
        if (_newSignerAddress == address(0)) revert InvalidSignerAddress();
        address previousSigner = signerAddress;
        signerAddress = _newSignerAddress;
        emit SignerAddressUpdated(previousSigner, _newSignerAddress);
    }

    function createNewBook(
        address _author,
        string memory _coverUri,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre,
        uint256 _nonce,
        uint48 _deadline,
        bytes calldata signature
    ) external whenNotPaused returns (address _createdBook) {
        _authorize(
            keccak256(
                abi.encode(
                    CREATE_NEW_BOOK_TYPEHASH,
                    _msgSender(),
                    _author,
                    keccak256(bytes(_coverUri)),
                    _initialPrice,
                    _daysForSecondarySales,
                    _lang,
                    keccak256(abi.encode(_genre)),
                    _nonce,
                    _deadline
                )
            ),
            _deadline,
            signature
        );
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
        uint48 _deadline,
        bytes calldata signature
    ) external whenNotPaused returns (address[] memory) {
        require(
            _author.length == _coverUri.length && _coverUri.length == _initialPrice.length
                && _initialPrice.length == _daysForSecondarySales.length
                && _daysForSecondarySales.length == _lang.length && _lang.length == _genre.length,
            "NalndaMarketplace: Array lengths should be equal!"
        );
        bytes32 argumentsHash =
            keccak256(abi.encode(_author, _coverUri, _initialPrice, _daysForSecondarySales, _lang, _genre));
        _authorize(
            keccak256(abi.encode(CREATE_NEW_BOOKS_TYPEHASH, _msgSender(), argumentsHash, _nonce, _deadline)),
            _deadline,
            signature
        );
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
        if (_tokenAddress == address(0)) revert InvalidTokenAddress();
        IERC20 token = IERC20(_tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        require(bal != 0, "NalndaMarketplace: Nothing to withdraw!");
        token.safeTransfer(owner(), bal);
    }

    function withdrawAnyEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance != 0, "NalndaMarketplace: Nothing to withdraw!");
        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "NalndaMarketplace: ETH Transfer failed!");
    }

    function listCover(
        NalndaBook _book,
        uint256 _tokenId,
        uint256 _price,
        uint256 _nonce,
        uint48 _deadline,
        bytes calldata signature
    ) external whenNotPaused {
        if (!createdBooks[address(_book)]) revert UnknownBook();
        require(_tokenId <= _book.coverIdCounter(), "NalndaMarketplace: Invalid tokenId provided!");
        require(_book.ownerOf(_tokenId) == _msgSender(), "NalndaMarketplace: Seller should own the NFT to list!");
        _authorize(
            keccak256(
                abi.encode(LIST_COVER_TYPEHASH, _msgSender(), address(_book), _tokenId, _price, _nonce, _deadline)
            ),
            _deadline,
            signature
        );
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

    function unlistCover(uint256 _orderId, uint256 _nonce, uint48 _deadline, bytes calldata signature) external {
        require(_orderId <= lastOrderId, "NalndaMarketplace: Invalid order id!");
        require(ORDER[_orderId].stage == Stage.LISTED, "NalndaMarketplace: NFT not yet listed / already sold!");
        require(
            _msgSender() == ORDER[_orderId].seller || _msgSender() == owner(),
            "NalndaMarketplace: Only seller or marketplace admin can unlist!"
        );
        _authorize(
            keccak256(abi.encode(UNLIST_COVER_TYPEHASH, _msgSender(), _orderId, _nonce, _deadline)),
            _deadline,
            signature
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

    function buyCover(uint256 _orderId, uint256 _nonce, uint48 _deadline, bytes calldata signature)
        external
        whenNotPaused
    {
        require(_orderId <= lastOrderId, "NalndaMarketplace: Invalid order id!");
        require(ORDER[_orderId].book.approved() == true, "NalndaMarketplace: Sales on this book are disabled!");
        require(ORDER[_orderId].stage == Stage.LISTED, "NalndaMarketplace: NFT not yet listed / already sold!");
        _authorize(
            keccak256(abi.encode(BUY_COVER_TYPEHASH, _msgSender(), _orderId, _nonce, _deadline)), _deadline, signature
        );
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

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        if (!paused) revert MarketplaceNotPaused();
        (newImplementation);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("NalndaMarketplace: Ownership cannot be renounced!");
    }

    function _msgSender() internal view override(Context) returns (address) {
        if (msg.data.length >= _contextSuffixLength() && isTrustedForwarder(msg.sender)) {
            return address(bytes20(msg.data[msg.data.length - _contextSuffixLength():]));
        }
        return super._msgSender();
    }

    function _msgData() internal view override(Context) returns (bytes calldata) {
        if (msg.data.length >= _contextSuffixLength() && isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - _contextSuffixLength()];
        }
        return super._msgData();
    }

    function _contextSuffixLength() internal pure override(Context) returns (uint256) {
        return 20;
    }
}
