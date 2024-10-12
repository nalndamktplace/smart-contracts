// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NalndaDiscounts is Ownable {
    address public immutable marketplace;
    mapping(bytes32 => DiscountCoupon) public discountCoupons;

    struct DiscountCoupon {
        uint256 discountPercentage;
        bytes32 couponCode;
        uint256 expiryTimestamp;
    }

    event DiscountCouponAdded(bytes32 couponCode, uint256 discountPercentage, uint256 expiryTimestamp);
    event DiscountCouponRemoved(bytes32 couponCode);

    constructor(address _owner, address _marketplace) Ownable(_owner) {
        marketplace = _marketplace;
    }

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "NalndaDiscounts: Only marketplace can call this function");
        _;
    }

    function addNewDiscountCoupon(bytes32 _couponCode, uint256 _discountPercentage, uint256 _expiryTimestamp)
        external
        onlyOwner
    {
        require(
            _discountPercentage > 0 && _discountPercentage <= 100,
            "NalndaDiscounts: Discount percentage must be between 1 and 100"
        );
        require(discountCoupons[_couponCode].discountPercentage == 0, "NalndaDiscounts: Coupon code already exists");
        require(_expiryTimestamp > block.timestamp, "NalndaDiscounts: Expiry timestamp must be in the future");
        discountCoupons[_couponCode] = DiscountCoupon(_discountPercentage, _couponCode, _expiryTimestamp);
        emit DiscountCouponAdded(_couponCode, _discountPercentage, _expiryTimestamp);
    }

    function removeDiscountCoupon(bytes32 _couponCode) external onlyOwner {
        require(discountCoupons[_couponCode].discountPercentage > 0, "NalndaDiscounts: Coupon code does not exist");
        delete discountCoupons[_couponCode];
        emit DiscountCouponRemoved(_couponCode);
    }

    function getDiscountedPrice(uint256 _price, string calldata _cC) external view returns (uint256) {
        bytes32 _couponCode = keccak256(abi.encodePacked(_cC));
        DiscountCoupon memory discountCoupon = discountCoupons[_couponCode];
        if (discountCoupon.discountPercentage == 0) {
            return _price;
        }
        if (discountCoupon.expiryTimestamp < block.timestamp) {
            return _price;
        }
        return (_price * (100 - discountCoupon.discountPercentage)) / 100;
    }
}
