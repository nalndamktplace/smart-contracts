// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./tokens/NalndaToken.sol";
import "./interfaces/INalndaMarketplace.sol";

contract NalndaAirdrop is Ownable {
    NalndaToken immutable nalndaToken;
    uint256 public immutable maxAirdropTokens;
    INalndaMarketplace immutable marketplace;

    modifier onlyMarketplace() {
        require(msg.sender == address(marketplace), "Only the marketplace can call this function");
        _;
    }

    mapping(INalndaMarketplace.AirdropSlab => uint256) public tokensToDistributePerBook;
    mapping(INalndaMarketplace.AirdropSlab => uint256) public remainingEligibleBuyers; // slab to remaining eligible buyers
    mapping(address => INalndaMarketplace.AirdropSlab) public booksToSlab; // book address to slab
    mapping(address => bool) public allowDistributionByBook;

    constructor(address _initOwner, address _marketplace) {
        _transferOwnership(_initOwner);
        nalndaToken = new NalndaToken(address(this), _initOwner);
        maxAirdropTokens = 13500000 * 10 ** 18; // 13.5M
        require(nalndaToken.balanceOf(address(this)) == maxAirdropTokens, "Invalid airdrop token balance");
        marketplace = INalndaMarketplace(_marketplace);

        tokensToDistributePerBook[INalndaMarketplace.AirdropSlab.ZeroToFiveK] = 1000 * 10 ** nalndaToken.decimals();
        tokensToDistributePerBook[INalndaMarketplace.AirdropSlab.FiveK1ToTenK] = 500 * 10 ** nalndaToken.decimals();
        tokensToDistributePerBook[INalndaMarketplace.AirdropSlab.TenK1ToTwentyK] = 250 * 10 ** nalndaToken.decimals();
        tokensToDistributePerBook[INalndaMarketplace.AirdropSlab.TwentyK1ToThirtyK] = 150 * 10 ** nalndaToken.decimals();
        tokensToDistributePerBook[INalndaMarketplace.AirdropSlab.ThirtyK1ToFiftyK] = 100 * 10 ** nalndaToken.decimals();

        remainingEligibleBuyers[INalndaMarketplace.AirdropSlab.ZeroToFiveK] = 5000;
        remainingEligibleBuyers[INalndaMarketplace.AirdropSlab.FiveK1ToTenK] = 5000;
        remainingEligibleBuyers[INalndaMarketplace.AirdropSlab.TenK1ToTwentyK] = 10000;
        remainingEligibleBuyers[INalndaMarketplace.AirdropSlab.TwentyK1ToThirtyK] = 10000;
        remainingEligibleBuyers[INalndaMarketplace.AirdropSlab.ThirtyK1ToFiftyK] = 20000;
    }

    function setBookSlabAndAllowDistribution(address book, INalndaMarketplace.AirdropSlab slab)
        external
        onlyMarketplace
    {
        booksToSlab[book] = slab;
        allowDistributionByBook[book] = true;
    }

    modifier canDistribute(address book) {
        require(allowDistributionByBook[book], "Distribution not allowed for this book");
        _;
    }

    function currentNalndaBalance() public view returns (uint256) {
        return nalndaToken.balanceOf(address(this));
    }

    function distributeTokensIfAny(address buyer) public canDistribute(msg.sender) {
        if (isAirdropActive() == false) {
            return;
        }
        INalndaMarketplace.AirdropSlab slab = booksToSlab[msg.sender];
        if (slab == INalndaMarketplace.AirdropSlab.None) {
            return;
        }
        if (remainingEligibleBuyers[slab] == 0) {
            return;
        }
        uint256 nalndaBalance = nalndaToken.balanceOf(address(this));
        if (nalndaBalance < tokensToDistributePerBook[slab]) {
            return;
        }
        nalndaToken.transfer(buyer, tokensToDistributePerBook[slab]);
        remainingEligibleBuyers[slab] -= 1;
    }

    function withdrawAllNalndaAndStopAirdrop() external onlyOwner {
        nalndaToken.transfer(owner(), nalndaToken.balanceOf(address(this)));
    }

    function isAirdropActive() public view returns (bool) {
        return nalndaToken.balanceOf(address(this)) > 0;
    }

    function withdrawAnyEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
