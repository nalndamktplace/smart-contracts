// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/INalndaMarketplaceITO.sol";
import "./interfaces/INalndaDiscount.sol";

contract NalndaITOBook is ERC721, Pausable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    enum ITOStage {
        NOT_STARTED,
        STARTED,
        ENDED
    }

    Counters.Counter public coverIdCounter;
    IERC20 public immutable NALNDA;
    INalndaMarketplaceITO public immutable marketplaceContract;
    uint256 public immutable protocolMintFee;
    uint256 public immutable protocolITOMintFee;
    uint256 public immutable protocolFee;
    uint256 public immutable bookOwnerShare;
    bool public startNormalSalesTransfers; //start normal sales after ITO sales
    ITOStage public currentITOStage;
    uint256 public immutable daysForSecondarySales;
    uint256 public secondarySalesTimestamp;
    uint256 public immutable bookLang;
    uint256[] public bookGenre;
    string public uri;
    uint256 public mintPrice;
    uint256 public authorEarningsPaidout;
    uint256 public totalDOs; //make sure it is not zero when you divide

    // token id => last sale price
    mapping(uint256 => uint256) public lastSoldPrice;
    //token id => timestamp of last transfer
    mapping(uint256 => uint256) public ownedAt;

    modifier onlyMarketplace() {
        require(_msgSender() == address(marketplaceContract));
        _;
    }

    modifier salesAndTransfersStarted() {
        require(
            startNormalSalesTransfers == true,
            "NalndaITOBook: Sales and transfers not started yet/already stopped!"
        );
        _;
    }

    constructor(
        uint256 _initialTotalDOs, //DOs: Distributed owners
        address _author,
        string memory _uri,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre
    ) ERC721("NalndaITOBookCover", "ITO-COVER") {
        require(
            _initialTotalDOs >= 500 && _initialTotalDOs <= 1000,
            "NalndaITOBook: Total distributed owners should be between 500 and 1000!"
        );
        require(
            _author != address(0),
            "NalndaITOBook: Author's address can't be null!"
        );
        require(
            bytes(_uri).length > 0,
            "NalndaITOBook: Empty string passed as cover URI!"
        );
        require(
            Address.isContract(_msgSender()) == true,
            "NalndaITOBook: Marketplace address is not a contract!"
        );
        require(
            _daysForSecondarySales >= 90 && _daysForSecondarySales <= 150,
            "NalndaITOBook: Days to secondary sales should be between 90 and 150!"
        );
        require(
            _lang >= 0 && _lang < 100,
            "NalndaITOBook: Book language tag should be between 1 and 100!"
        );
        for (uint256 i = 0; i < _genre.length; i++)
            require(
                _genre[i] >= 0 && _genre[i] < 100,
                "NalndaITOBook: Book genre tag should be between 1 and 60!"
            );
        totalDOs = _initialTotalDOs;
        startNormalSalesTransfers = false;
        currentITOStage = ITOStage.NOT_STARTED;
        daysForSecondarySales = _daysForSecondarySales;
        secondarySalesTimestamp = 0;
        bookLang = _lang;
        bookGenre = _genre;
        marketplaceContract = INalndaMarketplaceITO(_msgSender());
        transferOwnership(_author);
        protocolITOMintFee = 20; // fee in ITO phase
        protocolMintFee = 10; // fee after ITO phase
        protocolFee = 2; //2% on every transfer
        bookOwnerShare = 10; //10% on every transfer
        NALNDA = IERC20(marketplaceContract.NALNDA());
        uri = string(_uri);
        mintPrice = _initialPrice;
    }

    address[] public approvedForITO;
    mapping(address => bool) public addressApprovedForITO;
    mapping(address => bool) public claimed;

    function approveBookStartITO(address[] memory _approvedAddresses)
        external
        onlyMarketplace
    {
        require(
            currentITOStage == ITOStage.NOT_STARTED,
            "NalndaITOBook: ITO already started/ended!"
        );
        currentITOStage = ITOStage.STARTED;
        approvedForITO = _approvedAddresses;
        for (uint256 i = 0; i < _approvedAddresses.length; i++) {
            addressApprovedForITO[_approvedAddresses[i]] = true;
        }
    }

    // Just in case all the addresses are not added
    function addMoreApprovedAddresses(address[] memory _approvedAddresses)
        external
        onlyMarketplace
    {
        require(
            currentITOStage == ITOStage.STARTED,
            "NalndaITOBook: ITO not started/ended!"
        );
        for (uint256 i = 0; i < _approvedAddresses.length; i++) {
            approvedForITO.push(_approvedAddresses[i]);
            addressApprovedForITO[_approvedAddresses[i]] = true;
        }
    }

    function safeMintITO() external {
        require(
            currentITOStage == ITOStage.STARTED,
            "NalndaITOBook: ITO not started/already ended!"
        );
        require(
            addressApprovedForITO[_msgSender()] == true,
            "NalndaITOBook: You are not approved for ITO mint!"
        );
        require(
            claimed[_msgSender()] == false,
            "NalndaITOBook: You can only mint once during ITO!"
        );
        claimed[_msgSender()] = true; //prevents reentrancy
        //transfer the minting cost to the contract
        NALNDA.transferFrom(_msgSender(), address(this), mintPrice);
        INalndaDiscount discount = INalndaDiscount(
            marketplaceContract.discountContract()
        );
        uint256 protocolPayout;
        uint256 ownerShare;
        if (
            address(discount) != address(0) &&
            block.timestamp <= discount.expiry()
        ) {
            uint256 discountPercent = discount.getDiscount(_msgSender());
            uint256 cashbackPayout = (mintPrice * discountPercent) / 100;
            if (cashbackPayout != 0) {
                //send dicount cashback to buyer/minter
                NALNDA.transfer(_msgSender(), cashbackPayout);
            }
            protocolPayout =
                (mintPrice * (protocolITOMintFee - discountPercent)) /
                100;
            ownerShare = mintPrice - protocolPayout - cashbackPayout;
        } else {
            protocolPayout = (mintPrice * protocolITOMintFee) / 100;
            ownerShare = mintPrice - protocolPayout;
        }
        //send commision to marketplaceContract
        NALNDA.transfer(address(marketplaceContract), protocolPayout);
        //send author's share to the book owner
        NALNDA.transfer(owner(), ownerShare);
        authorEarningsPaidout += ownerShare;
        coverIdCounter.increment();
        uint256 _tokenId = coverIdCounter.current();
        lastSoldPrice[_tokenId] = mintPrice;
        ownedAt[_tokenId] = block.timestamp;
        //first mint for author then transfer to buyer
        _safeMint(owner(), _tokenId);
        _transfer(owner(), _msgSender(), _tokenId);
        //if total Distributed Owners have minted their tokens start sales and transfers
        if (_tokenId == totalDOs) {
            _startSalesTransfers();
        }
    }

    // Ideally sales and transfers sould start after fixed number of tokens are minted,
    // but in case it does not happen marketplace admin can start them manually
    function startSalesTransfersManually() external onlyMarketplace {
        require(
            currentITOStage == ITOStage.STARTED,
            "NalndaITOBook: ITO not started/already ended!"
        );
        require(
            startNormalSalesTransfers == false,
            "NalndaITOBook: Sales and transfers already started!"
        );
        //check with keshav
        // require(
        //     coverIdCounter.current() != 0,
        //     "NalndaITOBook: Can't start sales and transfers in case of 0 DOs!"
        // );
        _startSalesTransfers();
        totalDOs = coverIdCounter.current();
    }

    function _startSalesTransfers() internal {
        currentITOStage = ITOStage.ENDED; //end ITO
        startNormalSalesTransfers = true; // start normal sales and transfers
        secondarySalesTimestamp =
            block.timestamp +
            daysForSecondarySales *
            1 days;
    }

    function stopSalesTransfers() external onlyMarketplace {
        require(
            currentITOStage == ITOStage.STARTED ||
                startNormalSalesTransfers == true,
            "NalndaITOBook: Either the ITO should be going on or normal sales and transfers should be going on!"
        );
        secondarySalesTimestamp = 0;
        currentITOStage = ITOStage.ENDED;
        startNormalSalesTransfers = false;
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

    function pause() public salesAndTransfersStarted onlyOwner {
        _pause();
    }

    function unpause() public salesAndTransfersStarted onlyOwner {
        _unpause();
    }

    //owner should be able to mint for free at any point
    function ownerMint(address to) external salesAndTransfersStarted onlyOwner {
        coverIdCounter.increment();
        uint256 tokenId = coverIdCounter.current();
        ownedAt[tokenId] = block.timestamp;
        if (to != owner()) {
            //first mint for author then transfer
            _safeMint(owner(), tokenId);
            _transfer(owner(), to, tokenId);
        } else _safeMint(owner(), tokenId);
    }

    function batchOwnerMint(address[] memory addresses)
        external
        salesAndTransfersStarted
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            coverIdCounter.increment();
            uint256 tokenId = coverIdCounter.current();
            ownedAt[tokenId] = block.timestamp;
            if (addresses[i] != owner()) {
                //first mint for author then transfer
                _safeMint(owner(), tokenId);
                _transfer(owner(), addresses[i], tokenId);
            } else _safeMint(owner(), tokenId);
        }
    }

    //public method for minting new cover
    function safeMint(address to) external salesAndTransfersStarted {
        //transfer the minting cost to the contract
        NALNDA.transferFrom(_msgSender(), address(this), mintPrice);
        INalndaDiscount discount = INalndaDiscount(
            marketplaceContract.discountContract()
        );
        uint256 protocolPayout;
        uint256 ownerShare;
        if (
            address(discount) != address(0) &&
            block.timestamp <= discount.expiry()
        ) {
            uint256 discountPercent = discount.getDiscount(_msgSender());
            uint256 cashbackPayout = (mintPrice * discountPercent) / 100;
            if (cashbackPayout != 0) {
                //send dicount cashback to buyer/minter
                NALNDA.transfer(_msgSender(), cashbackPayout);
            }
            protocolPayout =
                (mintPrice * (protocolMintFee - discountPercent)) /
                100;
            ownerShare = mintPrice - protocolPayout - cashbackPayout;
        } else {
            protocolPayout = (mintPrice * protocolMintFee) / 100;
            ownerShare = mintPrice - protocolPayout;
        }
        //send commision to marketplaceContract
        NALNDA.transfer(address(marketplaceContract), protocolPayout);
        //send author's share to the book owner
        NALNDA.transfer(owner(), ownerShare);
        authorEarningsPaidout += ownerShare;
        coverIdCounter.increment();
        uint256 _tokenId = coverIdCounter.current();
        lastSoldPrice[_tokenId] = mintPrice;
        ownedAt[_tokenId] = block.timestamp;
        //first mint for author then transfer to buyer
        _safeMint(owner(), _tokenId);
        _transfer(owner(), to, _tokenId);
    }

    function batchSafeMint(address[] memory addresses)
        external
        salesAndTransfersStarted
    {
        //transfer the minting cost to the contract
        uint256 cost = mintPrice * addresses.length;
        NALNDA.transferFrom(_msgSender(), address(this), cost);
        INalndaDiscount discount = INalndaDiscount(
            marketplaceContract.discountContract()
        );
        uint256 protocolPayout;
        uint256 ownerShare;
        if (
            address(discount) != address(0) &&
            block.timestamp <= discount.expiry()
        ) {
            uint256 discountPercent = discount.getDiscount(_msgSender());
            uint256 cashbackPayout = (cost * discountPercent) / 100;
            if (cashbackPayout != 0) {
                //send dicount cashback to buyer/minter
                NALNDA.transfer(_msgSender(), cashbackPayout);
            }
            protocolPayout = (cost * (protocolMintFee - discountPercent)) / 100;
            ownerShare = cost - protocolPayout - cashbackPayout;
        } else {
            protocolPayout = (cost * protocolMintFee) / 100;
            ownerShare = cost - protocolPayout;
        }
        //send commision to marketplaceContract
        NALNDA.transfer(address(marketplaceContract), protocolPayout);
        //send author's share to the book owner
        NALNDA.transfer(owner(), ownerShare);
        authorEarningsPaidout += ownerShare;
        for (uint256 i = 0; i < addresses.length; i++) {
            coverIdCounter.increment();
            uint256 _tokenId = coverIdCounter.current();
            lastSoldPrice[_tokenId] = mintPrice;
            ownedAt[_tokenId] = block.timestamp;
            //first mint for author then transfer to buyer
            _safeMint(owner(), _tokenId);
            _transfer(owner(), addresses[i], _tokenId);
        }
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
    ) public virtual override salesAndTransfersStarted {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        require(
            block.timestamp >=
                ownedAt[tokenId] +
                    marketplaceContract.transferAfterDays() *
                    1 days,
            "NalndaITOBook: Transfer not allowed!"
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
    ) public virtual override salesAndTransfersStarted {
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
            "NalndaITOBook: Transfer not allowed!"
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
        require(
            currentITOStage == ITOStage.ENDED &&
                startNormalSalesTransfers == false,
            "NalndaITOBook: Can't burn during ITO phase!"
        );
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
        revert("NalndaITOBook: Ownership of a book cannot be renounced!");
    }
}
