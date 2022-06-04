// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/INalndaMarketplace.sol";

//renownce ownership discussion

contract NalndaBook is ERC721, Pausable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public coverIdCounter;
    IERC20 public immutable NALNDA;
    INalndaMarketplace public immutable marketplaceContract;
    uint256 public immutable protocolMintFee;
    uint256 public immutable protocolFee;
    uint256 public immutable bookOwnerShare;
    uint256 public immutable creationTimestamp;
    uint256 public immutable secondarySalesTimestamp;
    uint256 public immutable bookLang;
    uint256 public immutable bookGenre;
    string public uri;
    uint256 public mintPrice;
    uint256 public authorEarningsPaidout;
    uint256 public totalCommisionsPaidOut;

    // token id => last sale price
    mapping(uint256 => uint256) public lastSoldPrice;
    //token id => timestamp of last transfer
    mapping(uint256 => uint256) public ownedAt;

    modifier onlyMarketplace() {
        require(_msgSender() == address(marketplaceContract));
        _;
    }

    constructor(
        address _author,
        string memory _uri,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256 _genre
    ) ERC721("NalndaBookCover", "COVER") {
        require(
            _author != address(0),
            "NalndaBook: Author's address can't be null!"
        );
        require(
            bytes(_uri).length > 0,
            "NalndaBook: Empty string passed as cover URI!!!"
        );
        require(
            Address.isContract(_msgSender()) == true,
            "NalndaBook: Primary sales address is not a contract!!!"
        );
        require(
            _daysForSecondarySales >= 90 && _daysForSecondarySales <= 150,
            "NalndaBook: Days to secondary sales should be between 90 and 150!"
        );
        require(
            _lang > 0 && _lang <= 100,
            "NalndaBook: Book language tag should be between 1 and 100!"
        );
        require(
            _genre > 0 && _genre <= 60,
            "NalndaBook: Book genre tag should be between 1 and 60!"
        );
        creationTimestamp = block.timestamp;
        bookLang = _lang;
        bookGenre = _genre;
        secondarySalesTimestamp =
            block.timestamp +
            _daysForSecondarySales *
            1 days;
        marketplaceContract = INalndaMarketplace(_msgSender());
        transferOwnership(_author);
        protocolMintFee = marketplaceContract.protocolMintFee();
        protocolFee = 2; //2% on every transfer
        bookOwnerShare = 10; //10% on every transfer
        NALNDA = IERC20(marketplaceContract.NALNDA());
        uri = string(_uri);
        mintPrice = _initialPrice;
    }

    function changeMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return uri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //owner should be able to mint for free at any point
    function ownerMint(address to) external onlyOwner {
        coverIdCounter.increment();
        uint256 tokenId = coverIdCounter.current();
        ownedAt[tokenId] = block.timestamp;
        if (to != owner()) {
            //first mint for author then transfer
            _safeMint(owner(), tokenId);
            _transfer(owner(), to, tokenId);
        } else _safeMint(owner(), tokenId);
    }

    //public method for minting new cover
    function safeMint(address to) external {
        //transfer the minting cost to the contract
        NALNDA.transferFrom(_msgSender(), address(this), mintPrice);
        //send commision to marketplaceContract
        uint256 commisionPayout = (mintPrice * protocolMintFee) / 100;
        totalCommisionsPaidOut += commisionPayout;
        NALNDA.transfer(address(marketplaceContract), commisionPayout);
        //send author's share to the author
        uint256 authorShare = mintPrice - commisionPayout;
        authorEarningsPaidout += authorShare;
        NALNDA.transfer(owner(), authorShare);
        // totalEarningsPayout += mintPrice;
        coverIdCounter.increment();
        uint256 _tokenId = coverIdCounter.current();
        lastSoldPrice[_tokenId] = mintPrice;
        ownedAt[_tokenId] = block.timestamp;
        //first mint for author then transfer to buyer
        _safeMint(owner(), _tokenId);
        _transfer(owner(), to, _tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        //conditions for commisions go here
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        require(
            block.timestamp >=
                ownedAt[tokenId] +
                    marketplaceContract.transferAfterDays() *
                    1 days,
            "NalndaBook: Transfer not allowed!"
        );
        _chargeTransferFees(tokenId);
        ownedAt[tokenId] = block.timestamp;
        _safeTransfer(from, to, tokenId, data);
    }

    function _chargeTransferFees(uint256 tokenId) internal {
        uint256 lastSellPrice = lastSoldPrice[tokenId];
        //charging transfer fee
        uint256 totalFee = (lastSellPrice * (bookOwnerShare + protocolFee)) /
            100;
        NALNDA.transferFrom(_msgSender(), address(this), totalFee);
        //send owner share to the book owner
        uint256 ownerShare = (lastSellPrice * bookOwnerShare) / 100;
        NALNDA.transfer(owner(), ownerShare);
        //send protocol its share
        uint256 protocolShare = (lastSellPrice * protocolFee) / 100;
        NALNDA.transfer(address(marketplaceContract), protocolShare);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        require(
            block.timestamp >=
                ownedAt[tokenId] +
                    marketplaceContract.transferAfterDays() *
                    1 days,
            "NalndaBook: Transfer not allowed!"
        );
        _chargeTransferFees(tokenId);
        ownedAt[tokenId] = block.timestamp;
        _transfer(from, to, tokenId);
    }

    function marketplaceTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external onlyMarketplace {
        ownedAt[_tokenId] = block.timestamp;
        _transfer(_from, _to, _tokenId);
    }

    function updateLastSoldPrice(uint256 _tokenId, uint256 _price)
        external
        onlyMarketplace
    {
        lastSoldPrice[_tokenId] = _price;
    }

    function burn(uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        lastSoldPrice[tokenId] = 0;
        ownedAt[tokenId] = 0;
        _burn(tokenId);
    }

    function renounceOwnership() public virtual override onlyOwner {
        revert("Ownership of a book cannot be renounced!");
    }
}
