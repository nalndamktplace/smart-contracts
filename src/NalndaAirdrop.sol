// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./tokens/NalndaToken.sol";
import "./NalndaMarketplace.sol";

contract NalndaAirdrop is Ownable {
    enum AirdropSlab {
        ZeroToFiveK,
        FiveK1ToTenK,
        TenK1ToTwentyK,
        TwentyK1ToThirtyK,
        ThirtyK1ToFiftyK,
        MoreThanFiftyK
    }

    NalndaToken public immutable nalndaToken;
    uint256 public immutable maxAirdropTokens;
    NalndaMarketplace immutable marketplace;

    uint256 private ctrForAirdrop;
    AirdropSlab public currentSlab;

    modifier onlyMarketplace() {
        require(msg.sender == address(marketplace), "Only the marketplace can call this function");
        _;
    }

    mapping(AirdropSlab => uint256) public tokensToDistributePerBook;

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

        ctrForAirdrop = 0;
    }

    modifier calledByBook(address book) {
        require(marketplace.createdBooks(book), "Only books created by the marketplace allowed!");
        _;
    }

    function currentNalndaBalance() public view returns (uint256) {
        return nalndaToken.balanceOf(address(this));
    }

    function distributeTokensIfAny(address buyer) public calledByBook(msg.sender) {
        if (isAirdropActive() == false) {
            return;
        }
        adjustSlabIfNeeded();
        if (currentSlab == AirdropSlab.MoreThanFiftyK) {
            return;
        }
        uint256 nalndaBalance = nalndaToken.balanceOf(address(this));
        if (nalndaBalance < tokensToDistributePerBook[currentSlab]) {
            return;
        }
        nalndaToken.transfer(buyer, tokensToDistributePerBook[currentSlab]);
    }

    function adjustSlabIfNeeded() private {
        if (currentSlab == AirdropSlab.MoreThanFiftyK) {
            return;
        }
        ++ctrForAirdrop;
        if (ctrForAirdrop > 0 && ctrForAirdrop <= 5000) {
            if (currentSlab != AirdropSlab.ZeroToFiveK) {
                currentSlab = AirdropSlab.ZeroToFiveK;
            }
        } else if (ctrForAirdrop > 5000 && ctrForAirdrop <= 10000) {
            if (currentSlab != AirdropSlab.FiveK1ToTenK) {
                currentSlab = AirdropSlab.FiveK1ToTenK;
            }
        } else if (ctrForAirdrop > 10000 && ctrForAirdrop <= 20000) {
            if (currentSlab != AirdropSlab.TenK1ToTwentyK) {
                currentSlab = AirdropSlab.TenK1ToTwentyK;
            }
        } else if (ctrForAirdrop > 20000 && ctrForAirdrop <= 30000) {
            if (currentSlab != AirdropSlab.TwentyK1ToThirtyK) {
                currentSlab = AirdropSlab.TwentyK1ToThirtyK;
            }
        } else if (ctrForAirdrop > 30000 && ctrForAirdrop <= 50000) {
            if (currentSlab != AirdropSlab.ThirtyK1ToFiftyK) {
                currentSlab = AirdropSlab.ThirtyK1ToFiftyK;
            }
        } else {
            if (currentSlab != AirdropSlab.MoreThanFiftyK) {
                currentSlab = AirdropSlab.MoreThanFiftyK;
            }
        }
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
