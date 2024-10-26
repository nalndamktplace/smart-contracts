// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract NalndaDiscounts is Ownable {
    using MessageHashUtils for bytes32;
    using ECDSA for bytes32;

    address public immutable marketplace;
    mapping(bytes32 => DiscountCoupon) public discountCoupons;
    uint256 immutable UINT256_MAX = type(uint256).max;
    uint256 public immutable chainId;
    uint256 public nonce_global;
    mapping(bytes32 => bool) public executedHashes;

    struct DiscountCoupon {
        bytes32 couponCode;
        uint256 discountPercentage;
        address verifyAddress;
        uint256 expiryTimestamp;
        uint256 claimsLeft;
    }

    constructor(address _owner, address _marketplace) Ownable(_owner) {
        marketplace = _marketplace;
        nonce_global = 0;
        uint256 _chainid;
        assembly {
            _chainid := chainid()
        }
        chainId = _chainid;
    }

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "NalndaDiscounts: Only marketplace can call this function");
        _;
    }

    function addNewDiscountCoupon(
        address _couponVerifyAddress,
        uint256 _discountPercentage,
        uint256 _expiryTimestamp,
        uint256 _maxClaims
    ) external onlyOwner {
        require(nonce_global == UINT256_MAX, "NalndaDiscounts: No more discount coupons can be added");
        require(
            _discountPercentage > 0 && _discountPercentage <= 100,
            "NalndaDiscounts: Discount percentage must be between 1 and 100"
        );
        require(_expiryTimestamp > block.timestamp, "NalndaDiscounts: Expiry timestamp must be in the future");
        bytes32 _couponCode = keccak256(
            abi.encodePacked(
                address(this),
                chainId,
                _discountPercentage,
                _couponVerifyAddress,
                _expiryTimestamp,
                _maxClaims,
                nonce_global
            )
        );
        nonce_global++;
        discountCoupons[_couponCode] =
            DiscountCoupon(_couponCode, _discountPercentage, _couponVerifyAddress, _expiryTimestamp, _maxClaims);
    }

    function stopDiscountCoupon(bytes32 _couponCode) external onlyOwner {
        require(discountCoupons[_couponCode].discountPercentage > 0, "NalndaDiscounts: Coupon code does not exist");
        discountCoupons[_couponCode].expiryTimestamp = block.timestamp - 1;
    }

    function generateHashToSignForCoupon(bytes32 _couponCode, address _redeemAddress, uint256 _salt)
        public
        view
        returns (bytes32 hash)
    {
        hash = keccak256(abi.encodePacked(address(this), chainId, _couponCode, _redeemAddress, _salt));
    }

    // This function does not revert if the coupon code is invalid or expired
    function redeemCoupon(
        address _redeemAddress,
        uint256 _price,
        bytes32 _couponCode,
        bytes calldata _signature,
        uint256 _salt
    ) external onlyMarketplace returns (uint256) {
        bytes32 _hash = generateHashToSignForCoupon(_couponCode, _redeemAddress, _salt);
        uint256 updatedPrice = _getUpdatedPrice(_price, _couponCode, _signature, _hash);
        discountCoupons[_couponCode].claimsLeft--;
        executedHashes[_hash] = true;
        return updatedPrice;
    }

    function canRedeemCoupon(
        address _redeemAddress,
        uint256 _price,
        bytes32 _couponCode,
        bytes calldata _signature,
        uint256 _salt
    ) external view returns (bool) {
        DiscountCoupon memory discountCoupon = discountCoupons[_couponCode];
        if (discountCoupon.discountPercentage == 0) {
            return true;
        }
        bytes32 _hash = generateHashToSignForCoupon(_couponCode, _redeemAddress, _salt);
        uint256 updatedPrice = _getUpdatedPrice(_price, _couponCode, _signature, _hash);
        return updatedPrice < _price;
    }

    function _getUpdatedPrice(uint256 _price, bytes32 _couponCode, bytes calldata _signature, bytes32 hash)
        private
        view
        returns (uint256)
    {
        DiscountCoupon memory discountCoupon = discountCoupons[_couponCode];
        if (discountCoupon.discountPercentage == 0) {
            return _price;
        }
        if (discountCoupon.expiryTimestamp < block.timestamp) {
            return _price;
        }
        if (discountCoupon.claimsLeft == 0) {
            return _price;
        }
        if (executedHashes[hash]) {
            return _price;
        }
        if (!_verifySignature(hash, discountCoupon.verifyAddress, _signature)) {
            return _price;
        }
        return (_price * (100 - discountCoupon.discountPercentage)) / 100;
    }

    function getUpdatedPrice(
        address _redeemAddress,
        uint256 _price,
        bytes32 _couponCode,
        bytes calldata _signature,
        uint256 _salt
    ) external view returns (uint256) {
        bytes32 _hash = generateHashToSignForCoupon(_couponCode, _redeemAddress, _salt);
        return _getUpdatedPrice(_price, _couponCode, _signature, _hash);
    }

    function _verifySignature(bytes32 _hash, address _verifyAddress, bytes calldata _signature)
        private
        pure
        returns (bool isSigner)
    {
        bytes32 ethSignedHash = _hash.toEthSignedMessageHash();
        address recovered = ethSignedHash.recover(_signature);
        return recovered == _verifyAddress;
    }
}
