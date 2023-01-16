// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../mocks/NALNDA.sol";
import "../interfaces/INalndaMarketplace.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

//Contract for discounts on Nalnda covers. This contract can be used as a template for future discount contracts
contract NalndaDiscountV1 is Ownable {
    //set expiry to MAX_UINT if there is no expiry for the discount
    uint256 public expiry;
    IERC20 public immutable NALNDA;
    INalndaMarketplace public immutable marketplace;

    //tokenid to discounts
    mapping(uint256 => uint256) public discounts;

    function changeExpiry(uint256 _expiry) external onlyOwner {
        expiry = _expiry;
    }

    IERC1155 public immutable funkyReaders;

    uint256[] public tokenIds;

    constructor(
        address _NALNDA,
        address _marketplace,
        uint256[] memory _tokenIds,
        uint256[] memory _discounts
    ) {
        require(
            _NALNDA != address(0),
            "NalndaDiscountV1: NALNDA address can't be null!"
        );
        require(
            Address.isContract(_NALNDA) == true,
            "NalndaDiscountV1: NALNDA address is not a contract!!!"
        );
        require(
            Address.isContract(_marketplace) == true,
            "NalndaDiscountV1: Marketplace address is not a contract!!!"
        );
        require(
            _tokenIds.length == _discounts.length,
            "NalndaDiscountV1: Invalid token ids or discounts provided!"
        );
        tokenIds = _tokenIds;
        NALNDA = IERC20(_NALNDA);
        marketplace = INalndaMarketplace(_marketplace);
        expiry = 2**256 - 1; //never expires
        //deployed on matic mainnet
        funkyReaders = IERC1155(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            discounts[_tokenIds[i]] = _discounts[i];
        }
    }

    // discount resolver - write custom logic here - make sure discount is 0-10%
    function getDiscount(address _addr) external view returns (uint256) {
        uint256 _discount;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (funkyReaders.balanceOf(_addr, tokenIds[i]) > 0) {
                _discount = discounts[tokenIds[i]];
                break;
            }
        }
        if (_discount > 10) return 0;
        else return _discount;
    }
}
