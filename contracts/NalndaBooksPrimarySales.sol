// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NalndaBookCover.sol";

//primary sales /lazy minintg will only happen using NALNDA token.
contract NalndaBooksPrimarySales is Ownable {
    IERC20 public immutable NALNDA;
    uint256 public commissionPercent; //primarySalesCommission percentage for primary sale/lazy minting

    uint256 public totalBooks;
    //book to author
    mapping(address => address) public bookToAuthor;
    mapping(address => address[]) public authorToBooks;

    constructor(address _NALNDA, uint256 _initialCommissionPercent) {
        require(
            _NALNDA != address(0),
            "NalndaPrimarySales: NALNDA token's address can't be null!"
        );
        NALNDA = IERC20(_NALNDA);
        commissionPercent = _initialCommissionPercent;
        totalBooks = 0;
    }

    function changeCommissionPercent(uint256 _newCommissionPercent)
        external
        onlyOwner
    {
        commissionPercent = _newCommissionPercent;
    }

    function createNewBook(
        address _author,
        string memory _coverURI,
        uint256 _initialPrice
    ) external {
        require(
            _author != address(0),
            "NalndaPrimarySales: Author's address can't be null!"
        );
        require(
            bytes(_coverURI).length > 0,
            "NalndaPrimarySales: Empty string passed as cover URI!!!"
        );
        address bookAddress = address(
            new NalndaBookCover(_author, _coverURI, _initialPrice)
        );
        bookToAuthor[bookAddress] = _author;
        authorToBooks[_msgSender()].push(bookAddress);
        totalBooks++;
    }
}
