// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "../mocks/NALNDA.sol";
import "../interfaces/INalndaMarketplace.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//Contract for discounts on Nalnda covers. This contract can be used as a template for future discount contracts
contract NalndaDiscountV1 is Context {
    //set expiry to MAX_UINT if there is no expiry for the discount
    uint256 public immutable expiry;
    IERC20 public immutable NALNDA;
    INalndaMarketplace public immutable marketplace;

    modifier onlyMarketplace() {
        require(_msgSender() == address(marketplace));
        _;
    }

    constructor(
        address _NALNDA,
        address _marketplace // uint256 _expiry
    ) {
        require(
            _NALNDA != address(0),
            "NalndaDiscountV1: NALNDA token's address can't be null!"
        );
        require(
            Address.isContract(_NALNDA) == true,
            "NalndaDiscountV1: NALNDA address is not a contract!!!"
        );
        require(
            Address.isContract(_marketplace) == true,
            "NalndaDiscountV1: Marketplace address is not a contract!!!"
        );
        NALNDA = IERC20(_NALNDA);
        marketplace = INalndaMarketplace(_marketplace);
        expiry = 2**256 - 1;
    }

    // discount resolver
    function getDiscount(address _addr) external {}
}
