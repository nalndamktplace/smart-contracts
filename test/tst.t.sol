// SPDX-License-Identifier: None
pragma solidity 0.8.27;

import "forge-std/Test.sol";
import {NalndaMarketplace} from "../src/NalndaMarketplace.sol";
import {NalndaDiscounts} from "../src/NalndaDiscounts.sol";
import {NalndaBook} from "../src/NalndaBook.sol";
import {MockUSDT} from "../src/tokens/mockUSDT.sol";

contract TestContracts is Test {
    NalndaMarketplace marketplace;
    address bookOwnerAndCreator = vm.addr(1);
    NalndaDiscounts discounts;
    uint256 pvtKeyGenerated = 0xd691ec3c76fb1069972de9ce71f133c2e91813e797459ddf645bc032680473d0;
    address pubKeyGenerated = 0xacD3000330C0347CDe091b3F5Ec60B166b91c26c;
    uint256 chainId;
    MockUSDT purchaseToken;

    function setUp() public {
        purchaseToken = new MockUSDT();

        marketplace = new NalndaMarketplace(address(purchaseToken), bookOwnerAndCreator, bookOwnerAndCreator);
        discounts = marketplace.nalndaDiscounts();
        uint256 _chainid;
        assembly {
            _chainid := chainid()
        }
        chainId = _chainid;
    }

    function test_Discounts() public {
        uint256 _discountPercentage = 10;
        uint256 _expiryTimestamp = block.timestamp + 1 days;
        address _couponVerifyAddress = pubKeyGenerated;
        uint256 _maxClaims = 10;
        vm.prank(bookOwnerAndCreator);
        bytes32 _generatedCC =
            discounts.addNewDiscountCoupon(_couponVerifyAddress, _discountPercentage, _expiryTimestamp, _maxClaims);

        uint256 _initPrice = 100 * 10 ** 6;
        uint256[] memory _discounts = new uint256[](3);
        _discounts[0] = 1;
        _discounts[1] = 2;
        _discounts[2] = 3;
        vm.prank(bookOwnerAndCreator);
        // create a book
        NalndaBook book = NalndaBook(
            marketplace.createNewBook(bookOwnerAndCreator, "https://coveruri.com", _initPrice, 91, 0, _discounts)
        );

        address _buyer = vm.addr(2);
        vm.prank(_buyer);
        purchaseToken.approve(address(book), _initPrice);
        vm.prank(_buyer);
        purchaseToken.mint(_initPrice);

        uint256 _salt = 123;
        bytes32 msgHashToSign = discounts.generateHashToSignForCoupon(_generatedCC, _buyer, _salt);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHashToSign));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvtKeyGenerated, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // bytes memory sigFake = abi.encodePacked(bytes32(0), bytes32(0), uint8(0));

        vm.prank(_buyer);
        book.safeMint(_buyer, NalndaBook.DiscountData(_generatedCC, _salt, signature), false);
        //book.safeMint(_buyer, NalndaBook.DiscountData(0x0, 0, sigFake), false);
    }
}
