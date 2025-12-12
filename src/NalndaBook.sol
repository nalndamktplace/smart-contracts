// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./NalndaMarketplace.sol";

contract NalndaBook is ERC721, Ownable, Initializable, UUPSUpgradeable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    mapping(bytes32 => bool) public executed;
    uint256 public immutable chainId;

    uint256 private _nextTokenId;
    NalndaMarketplace public marketplaceContract;
    bool public approved;
    uint256 public daysForSecondarySales;
    uint256 public secondarySalesTimestamp;
    uint256 public bookLang;
    uint256[] public bookGenre;
    string public uri;
    uint256 public mintPrice;

    // token id => last sale price
    mapping(uint256 => uint256) public lastSoldPrice;
    //token id => timestamp of last transfer
    mapping(uint256 => uint256) public ownedAt;

    modifier onlyMarketplace() {
        require(_msgSender() == address(marketplaceContract));
        _;
    }

    modifier marketplaceApproved() {
        require(approved == true, "NalndaBook: Book unapproved from marketplace!");
        _;
    }

    constructor(address initialOwner) ERC721("NalndaBookCover", "COVER") Ownable(initialOwner) {
        _disableInitializers();
        uint256 _chainid;
        assembly {
            _chainid := chainid()
        }
        chainId = _chainid;
    }

    function coverIdCounter() public view returns (uint256) {
        return _nextTokenId;
    }

    function initialize(
        address _author,
        string memory _uri,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre
    ) public virtual initializer {
        require(_author != address(0), "NalndaBook: Author's address can't be null!");
        require(bytes(_uri).length > 0, "NalndaBook: Empty string passed as cover URI!!!");
        require(
            _daysForSecondarySales >= 90 && _daysForSecondarySales <= 150,
            "NalndaBook: Days to secondary sales should be between 90 and 150!"
        );
        require(_lang >= 0 && _lang < 100, "NalndaBook: Book language tag should be between 1 and 100!");
        for (uint256 i = 0; i < _genre.length; i++) {
            require(_genre[i] >= 0 && _genre[i] < 100, "NalndaBook: Book genre tag should be between 1 and 60!");
        }
        approved = true; // for testing -- should be false in production
        daysForSecondarySales = _daysForSecondarySales;
        secondarySalesTimestamp = 2 ** 256 - 1;
        bookLang = _lang;
        bookGenre = _genre;
        marketplaceContract = NalndaMarketplace(_msgSender());
        _transferOwnership(_author);
        uri = string(_uri);
        mintPrice = _initialPrice;
    }

    function changeApproval(bool _newApproved) external onlyMarketplace {
        if (_newApproved == true) {
            require(approved == false, "NalndaBook: Already approved!");
            secondarySalesTimestamp = block.timestamp + daysForSecondarySales * 1 days;
        } else {
            require(approved == true, "NalndaBook: Already unapproved!");
            secondarySalesTimestamp = 2 ** 256 - 1;
        }
        approved = _newApproved;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId > 0 && tokenId <= _nextTokenId, "NalndaBook: URI query for nonexistent token");
        return uri;
    }

    function changeMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    //owner should be able to mint for free at any point
    function ownerMint(address to) external onlyOwner marketplaceApproved {
        _nextTokenId++;
        uint256 tokenId = _nextTokenId;
        ownedAt[tokenId] = block.timestamp;
        if (to != owner()) {
            //first mint for author then transfer
            _safeMint(owner(), tokenId);
            _transfer(owner(), to, tokenId);
        } else {
            _safeMint(owner(), tokenId);
        }
    }

    function batchOwnerMint(address[] memory addresses) external onlyOwner marketplaceApproved {
        for (uint256 i = 0; i < addresses.length; i++) {
            _nextTokenId++;
            uint256 tokenId = _nextTokenId;
            ownedAt[tokenId] = block.timestamp;
            if (addresses[i] != owner()) {
                //first mint for author then transfer
                _safeMint(owner(), tokenId);
                _transfer(owner(), addresses[i], tokenId);
            } else {
                _safeMint(owner(), tokenId);
            }
        }
    }

    function getHash(uint256 _nonce) public view returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(address(this), chainId, _nonce));
    }

    function verifySignature(bytes calldata _sig, uint256 _nonce) public view returns (bool isValid) {
        bytes32 ethSignedHash = getHash(_nonce).toEthSignedMessageHash();
        isValid = (marketplaceContract.signerAddress() == ethSignedHash.recover(_sig));
    }

    //public method for minting new cover
    function safeMint(address to, uint256 _nonce, bytes calldata signature) external marketplaceApproved {
        bytes32 hash = getHash(_nonce);
        require(!executed[hash], "NalndaBook: Hash has already been used!");
        require(verifySignature(signature, _nonce), "NalndaBook: Invalid signature!");
        executed[hash] = true;
        _nextTokenId++;
        uint256 _tokenId = _nextTokenId;
        lastSoldPrice[_tokenId] = mintPrice;
        ownedAt[_tokenId] = block.timestamp;
        _safeMint(owner(), _tokenId);
        _transfer(owner(), to, _tokenId);
    }

    function batchSafeMint(address[] memory addresses, uint256 _nonce, bytes calldata signature)
        external
        marketplaceApproved
    {
        bytes32 hash = getHash(_nonce);
        require(!executed[hash], "NalndaBook: Hash has already been used!");
        require(verifySignature(signature, _nonce), "NalndaBook: Invalid signature!");
        executed[hash] = true;
        for (uint256 i = 0; i < addresses.length; i++) {
            _nextTokenId++;
            uint256 _tokenId = _nextTokenId;
            lastSoldPrice[_tokenId] = mintPrice;
            ownedAt[_tokenId] = block.timestamp;
            _safeMint(owner(), _tokenId);
            _transfer(owner(), addresses[i], _tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        virtual
        override
        marketplaceApproved
    {
        require(
            block.timestamp >= ownedAt[tokenId] + marketplaceContract.transferAfterDays() * 1 days,
            "NalndaBook: Transfer not allowed!"
        );
        ownedAt[tokenId] = block.timestamp;
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function marketplaceTransfer(address _from, address _to, uint256 _tokenId) external onlyMarketplace {
        ownedAt[_tokenId] = block.timestamp;
        _transfer(_from, _to, _tokenId);
    }

    function updateLastSoldPrice(uint256 _tokenId, uint256 _price) external onlyMarketplace {
        lastSoldPrice[_tokenId] = _price;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        (newImplementation);
    }

    function renounceOwnership() public virtual override onlyOwner {
        revert("NalndaBook: Ownership of a book cannot be renounced!");
    }

    function withdrawAnyERC20(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        require(bal != 0, "NalndaBook: Nothing to withdraw!");
        token.transfer(owner(), bal);
    }

    function withdrawAnyEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance != 0, "NalndaBook: Nothing to withdraw!");
        payable(owner()).transfer(balance);
    }
}
