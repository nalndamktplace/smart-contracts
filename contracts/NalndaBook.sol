// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/INalndaMarketplace.sol";

//renownce ownership discussion

contract NalndaBook is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public coverIdCounter;
    IERC20 public immutable NALNDA;
    INalndaMarketplace public immutable marketplaceContract;
    uint256 public immutable protocolMintFee;
    uint256 public immutable protocolFee;
    uint256 public immutable bookOwnerShare;
    string public uri;
    uint256 public mintPrice;
    uint256 public authorEarningsPaidout;
    uint256 public totalCommisionsPaidOut;
    // token id => last sale price
    mapping(uint256 => uint256) lastSoldPrice;

    constructor(
        address _author,
        string memory _uri,
        uint256 _initialPrice
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
        _safeMint(to, tokenId);
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
        _chargeTransferFee(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

    function _chargeTransferFee(uint256 tokenId) internal {
        uint256 lastSellPrice = lastSoldPrice[tokenId];
        //charging transfer fee
        uint256 totalFee = (lastSellPrice * (bookOwnerShare + protocolFee)) /
            100;
        NALNDA.transferFrom(_msgSender(), address(this), totalFee);
        //send owner share to the book owner
        uint256 ownerShare = (lastSellPrice * bookOwnerShare) / 100;
        NALNDA.transfer(owner(), ownerShare);
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
        _chargeTransferFee(tokenId);
        _transfer(from, to, tokenId);
    }

    modifier onlyMarketplace() {
        require(_msgSender() == address(marketplaceContract));
        _;
    }

    function updateLastSoldPrice(uint256 _tokenId, uint256 _price)
        external
        onlyMarketplace
    {
        lastSoldPrice[_tokenId] = _price;
    }

    function marketplaceTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external onlyMarketplace {
        _transfer(from, to, tokenId);
    }
}
