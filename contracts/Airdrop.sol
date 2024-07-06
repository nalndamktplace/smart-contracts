// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./tokens/NalndaToken.sol";
import "./ICommon.sol";
import "./NalndaMarketplace.sol";

contract NalndaAirdrop is Ownable, ICommon {
    NalndaToken immutable nalndaToken;
    uint256 public immutable maxAirdropTokens;
    NalndaMarketplace immutable marketplace;

    modifier onlyMarketplace() {
        require(msg.sender == address(marketplace), "Only the marketplace can call this function");
        _;
    }

    mapping(AirdropSlab => uint256) public tokensToDistributePerBook;
    mapping(AirdropSlab => uint256) public remainingEligibleBuyers; // slab to remaining eligible buyers
    mapping(address => AirdropSlab) public booksToSlab; // book address to slab
    mapping(address => bool) public allowDistributionByBook;

    constructor(address _initOwner, address _marketplace) Ownable(_initOwner) {
        nalndaToken = new NalndaToken(address(this), _initOwner);
        maxAirdropTokens = 13500000 * 10 ** 18; // 13.5M
        require(nalndaToken.balanceOf(address(this)) == maxAirdropTokens, "Invalid airdrop token balance");
        marketplace = NalndaMarketplace(_marketplace);

        tokensToDistributePerBook[AirdropSlab.ZeroToFiveK] = 1000 * 10 ** nalndaToken.decimals();
        tokensToDistributePerBook[AirdropSlab.FiveK1ToTenK] = 500 * 10 ** nalndaToken.decimals();
        tokensToDistributePerBook[AirdropSlab.TenK1ToTwentyK] = 250 * 10 ** nalndaToken.decimals();
        tokensToDistributePerBook[AirdropSlab.TwentyK1ToThirtyK] = 150 * 10 ** nalndaToken.decimals();
        tokensToDistributePerBook[AirdropSlab.ThirtyK1ToFiftyK] = 100 * 10 ** nalndaToken.decimals();

        remainingEligibleBuyers[AirdropSlab.ZeroToFiveK] = 5000;
        remainingEligibleBuyers[AirdropSlab.FiveK1ToTenK] = 5000;
        remainingEligibleBuyers[AirdropSlab.TenK1ToTwentyK] = 10000;
        remainingEligibleBuyers[AirdropSlab.TwentyK1ToThirtyK] = 10000;
        remainingEligibleBuyers[AirdropSlab.ThirtyK1ToFiftyK] = 20000;
    }

    function setBookSlabAndAllowDistribution(address book, AirdropSlab slab) external onlyMarketplace {
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
        AirdropSlab slab = booksToSlab[msg.sender];
        if (slab == AirdropSlab.None) {
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
