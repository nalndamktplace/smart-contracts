// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/INalndaBooksPrimarySales.sol";

contract NalndaBookCover is ERC721, Pausable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    IERC20 public immutable NALNDA;
    INalndaBooksPrimarySales public immutable primarySalesContract;
    uint256 public immutable commissionPercent;
    address public immutable author;
    string private uri;
    uint256 public mintPrice;
    uint256 public authorEarningsPaidout;
    uint256 public totalCommisionsPaidOut;

    modifier onlyAuthor() {
        require(_msgSender() == author, "Not author!!!");
        _;
    }

    constructor(
        address _author,
        string memory _uri,
        uint256 _initialPrice
    ) ERC721("NalndaBookCover", "NBCVR") {
        require(
            _author != address(0),
            "NalndaBookCover: Author's address can't be null!"
        );
        require(
            bytes(_uri).length > 0,
            "NalndaBookCover: Empty string passed as cover URI!!!"
        );
        primarySalesContract = INalndaBooksPrimarySales(_msgSender());
        author = _author;
        commissionPercent = primarySalesContract.commissionPercent();
        NALNDA = IERC20(primarySalesContract.NALNDA());
        uri = string(_uri);
        mintPrice = _initialPrice;
    }

    function changeMintPrice(uint256 _newPrice) external onlyAuthor {
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

    function pause() public onlyAuthor {
        _pause();
    }

    function unpause() public onlyAuthor {
        _unpause();
    }

    //owner should be able to mint for free at any point
    function ownerMint(address to) external onlyAuthor {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    //public method for minting new cover
    function safeMint(address to) external {
        //transfer the minting cost to the contract
        NALNDA.transferFrom(_msgSender(), address(this), mintPrice);

        // totalEarningsPayout += mintPrice;
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        //first mint for author then transfer to buyer
        _safeMint(author, tokenId);
        _transfer(author, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
