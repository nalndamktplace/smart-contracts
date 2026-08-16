// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.36;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./NalndaMarketplace.sol";

contract NalndaBook is ERC721, Ownable, Initializable, UUPSUpgradeable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    error InvalidTrustedForwarder();
    error InvalidTokenAddress();
    error UnauthorizedMarketplaceOwner();
    error BookIsPaused();
    error BookNotPaused();

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant EIP712_NAME_HASH = keccak256("NalndaBook");
    bytes32 private constant EIP712_VERSION_HASH = keccak256("1");
    bytes32 private constant SAFE_MINT_TYPEHASH =
        keccak256("SafeMint(address caller,address to,uint256 nonce,uint48 deadline)");
    bytes32 private constant BATCH_SAFE_MINT_TYPEHASH =
        keccak256("BatchSafeMint(address caller,bytes32 addressesHash,uint256 nonce,uint48 deadline)");

    mapping(bytes32 => bool) public executed;
    uint256 public immutable chainId;

    uint256 private _nextTokenId;
    NalndaMarketplace public marketplaceContract;
    bool public paused;
    string public uri;

    // token id => last sale price
    mapping(uint256 => uint256) public lastSoldPrice;

    modifier onlyMarketplace() {
        require(_msgSender() == address(marketplaceContract));
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

    function name() public pure override returns (string memory) {
        return "NalndaBookCover";
    }

    function symbol() public pure override returns (string memory) {
        return "COVER";
    }

    function initialize(address _author, string memory _uri) public virtual initializer {
        require(_author != address(0), "NalndaBook: Author's address can't be null!");
        require(bytes(_uri).length > 0, "NalndaBook: Empty string passed as cover URI!!!");
        marketplaceContract = NalndaMarketplace(msg.sender);
        _transferOwnership(_author);
        uri = string(_uri);
    }

    function setPaused(bool shouldPause) external onlyMarketplace {
        if (shouldPause) {
            if (paused) revert BookIsPaused();
        } else if (!paused) {
            revert BookNotPaused();
        }
        paused = shouldPause;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return uri;
    }

    //owner should be able to mint for free at any point
    function ownerMint(address to) external onlyOwner {
        _nextTokenId++;
        uint256 tokenId = _nextTokenId;
        if (to != owner()) {
            //first mint for author then transfer
            _safeMint(owner(), tokenId);
            _transfer(owner(), to, tokenId);
        } else {
            _safeMint(owner(), tokenId);
        }
    }

    function batchOwnerMint(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _nextTokenId++;
            uint256 tokenId = _nextTokenId;
            if (addresses[i] != owner()) {
                //first mint for author then transfer
                _safeMint(owner(), tokenId);
                _transfer(owner(), addresses[i], tokenId);
            } else {
                _safeMint(owner(), tokenId);
            }
        }
    }

    function _authorize(bytes32 _structHash, uint48 _deadline, bytes calldata _signature) private {
        require(block.timestamp <= _deadline, "NalndaBook: Signature expired!");
        bytes32 domainSeparator = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, EIP712_NAME_HASH, EIP712_VERSION_HASH, block.chainid, address(this))
        );
        bytes32 digest = MessageHashUtils.toTypedDataHash(domainSeparator, _structHash);
        require(!executed[digest], "NalndaBook: Hash has already been used!");
        require(marketplaceContract.signerAddress() == digest.recover(_signature), "NalndaBook: Invalid signature!");
        executed[digest] = true;
    }

    //public method for minting new cover
    function safeMint(address to, uint256 _nonce, uint48 _deadline, bytes calldata signature) external {
        _authorize(keccak256(abi.encode(SAFE_MINT_TYPEHASH, _msgSender(), to, _nonce, _deadline)), _deadline, signature);
        _nextTokenId++;
        uint256 _tokenId = _nextTokenId;
        _safeMint(owner(), _tokenId);
        _transfer(owner(), to, _tokenId);
    }

    function batchSafeMint(address[] memory addresses, uint256 _nonce, uint48 _deadline, bytes calldata signature)
        external
    {
        bytes32 addressesHash = keccak256(abi.encode(addresses));
        _authorize(
            keccak256(abi.encode(BATCH_SAFE_MINT_TYPEHASH, _msgSender(), addressesHash, _nonce, _deadline)),
            _deadline,
            signature
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            _nextTokenId++;
            uint256 _tokenId = _nextTokenId;
            _safeMint(owner(), _tokenId);
            _transfer(owner(), addresses[i], _tokenId);
        }
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        if (_msgSender() != address(marketplaceContract)) {
            if (marketplaceContract.paused()) revert NalndaMarketplace.MarketplacePaused();
            if (paused) revert BookIsPaused();
        }
        return super._update(to, tokenId, auth);
    }

    function marketplaceTransfer(address _from, address _to, uint256 _tokenId) external onlyMarketplace {
        _transfer(_from, _to, _tokenId);
    }

    function updateLastSoldPrice(uint256 _tokenId, uint256 _price) external onlyMarketplace {
        lastSoldPrice[_tokenId] = _price;
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        if (_msgSender() != marketplaceContract.owner()) revert UnauthorizedMarketplaceOwner();
        if (!marketplaceContract.paused()) revert NalndaMarketplace.MarketplaceNotPaused();
        (newImplementation);
    }

    function renounceOwnership() public virtual override onlyOwner {
        revert("NalndaBook: Ownership of a book cannot be renounced!");
    }

    function trustedForwarder() public view returns (address) {
        return marketplaceContract.trustedForwarder();
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == trustedForwarder();
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

    function withdrawAnyERC20(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(0)) revert InvalidTokenAddress();
        IERC20 token = IERC20(_tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        require(bal != 0, "NalndaBook: Nothing to withdraw!");
        token.safeTransfer(owner(), bal);
    }

    function withdrawAnyEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance != 0, "NalndaBook: Nothing to withdraw!");
        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "NalndaBook: ETH Transfer failed!");
    }
}
