// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NalndaITOBook.sol";
import "./NalndaMarketplaceITO.sol";
import "../interfaces/INalndaITOBook.sol";
import "../Dependencies/NalndaMasterBase.sol";

contract NalndaMaster is NalndaMasterBase, Ownable {
    event RevenueWithdrawn(uint256 _revenueWithdrawn);

    constructor(address _NALNDA) {
        require(_NALNDA != address(0), "NalndaMaster: NALNDA token's address can't be null!");
        NALNDA = IERC20(_NALNDA);
        ITOMarketplace = address(new NalndaMarketplaceITO(_NALNDA));
        transferAfterDays = 21; //21 days
        secondarySaleAfterDays = 21; //user should have owned cover for atlease 21 days
        totalBooksCreated = 0;
    }

    function changeTransferAfterDays(uint256 _days) external onlyOwner {
        transferAfterDays = _days;
    }

    function changeSecondarySaleAfterDays(uint256 _days) external onlyOwner {
        secondarySaleAfterDays = _days;
    }

    function bookOwner(address _book) public view returns (address author) {
        author = Ownable(_book).owner();
    }

    // ITO functions
    function createNewITOBook(
        address _author,
        uint256 _initialTotalDOs,
        string memory _coverURI,
        uint256 _initialPrice,
        uint256 _daysForSecondarySales,
        uint256 _lang,
        uint256[] memory _genre
    ) external {
        require(_author != address(0), "NalndaMaster: Author address can't be null!");
        require(bytes(_coverURI).length > 0, "NalndaMaster: Empty string passed as cover URI!");
        require(
            _daysForSecondarySales >= 90 && _daysForSecondarySales <= 150,
            "NalndaMaster: Days to secondary sales should be between 90 and 150!"
        );
        require(_lang > 0 && _lang <= 100, "NalndaMaster: Book language tag should be between 1 and 100!");
        for (uint256 i = 0; i < _genre.length; i++) {
            require(_genre[i] > 0 && _genre[i] <= 60, "NalndaMaster: Book genre tag should be between 1 and 60!");
        }
        address _addressOutput = address(
            new NalndaITOBook(
                _initialTotalDOs, _author, _coverURI, _initialPrice, _daysForSecondarySales, _lang, _genre
            )
        );
        authorToBooks[_msgSender()].push(_addressOutput);
        totalBooksCreated++;
    }

    function approveBookStartITO(address _book, address[] memory _approvedAddresses) public onlyOwner {
        INalndaITOBook(_book).approveBookStartITO(_approvedAddresses);
    }

    function addMoreApprovedAddressesITO(address _book, address[] memory _approvedAddresses) external onlyOwner {
        INalndaITOBook(_book).addMoreApprovedAddresses(_approvedAddresses);
    }

    function startSalesTransfersManuallyITO(address _book) external onlyOwner {
        INalndaITOBook(_book).startSalesTransfersManually();
    }

    function stopSalesTransfersITO(address[] memory _books) external onlyOwner {
        for (uint256 i = 0; i < _books.length; i++) {
            INalndaITOBook(_books[i]).stopSalesTransfers();
        }
    }

    function withdrawRevenue() external onlyOwner {
        uint256 balance = getNALNDABalance();
        require(balance != 0, "NalndaMaster: Nothing to withdraw!");
        NALNDA.transfer(owner(), balance);
        emit RevenueWithdrawn(balance);
    }

    function getNALNDABalance() public view returns (uint256 bal) {
        bal = NALNDA.balanceOf((address(this)));
    }
}
