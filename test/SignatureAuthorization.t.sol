// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.36;

import "forge-std/Test.sol";
import "../src/NalndaMarketplace.sol";
import "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract NalndaBookV2 is NalndaBook {
    constructor(address initialOwner) NalndaBook(initialOwner) {}

    function version() external pure returns (uint256) {
        return 2;
    }
}

contract NalndaMarketplaceV2 is NalndaMarketplace {
    function version() external pure returns (uint256) {
        return 2;
    }
}

contract FakeBook {
    function coverIdCounter() external pure returns (uint256) {
        return 1;
    }

    function ownerOf(uint256) external view returns (address) {
        return msg.sender;
    }
}

contract SignatureAuthorizationTest is Test {
    uint256 private constant SIGNER_PRIVATE_KEY = 0xA11CE;
    uint256 private constant NEW_SIGNER_PRIVATE_KEY = 0xCAFE;
    uint256 private constant USER_PRIVATE_KEY = 0xB0B;
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant LIST_COVER_TYPEHASH =
        keccak256("ListCover(address seller,address book,uint256 tokenId,uint256 price,uint256 nonce,uint48 deadline)");
    bytes32 private constant UNLIST_COVER_TYPEHASH =
        keccak256("UnlistCover(address caller,uint256 orderId,uint256 nonce,uint48 deadline)");
    bytes32 private constant SAFE_MINT_TYPEHASH =
        keccak256("SafeMint(address caller,address to,uint256 nonce,uint48 deadline)");
    bytes32 private constant FORWARD_REQUEST_TYPEHASH = keccak256(
        "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,uint48 deadline,bytes data)"
    );

    NalndaMarketplace private marketplace;
    NalndaBook private book;
    ERC2771Forwarder private forwarder;

    address private signer;
    address private author = makeAddr("author");
    address private recipient = makeAddr("recipient");
    uint48 private authorizationDeadline;

    function setUp() public {
        vm.warp(1_000_000);
        authorizationDeadline = uint48(block.timestamp + 5 minutes);
        signer = vm.addr(SIGNER_PRIVATE_KEY);
        forwarder = new ERC2771Forwarder("NalndaForwarder");
        NalndaMarketplace implementation = new NalndaMarketplace();
        marketplace = NalndaMarketplace(
            payable(address(
                    new ERC1967Proxy(
                        address(implementation),
                        abi.encodeCall(NalndaMarketplace.initialize, (address(this), signer, address(forwarder)))
                    )
                ))
        );

        book = NalndaBook(payable(marketplace.createNewBook(author, "ipfs://cover")));
    }

    function testMintSignatureCannotBeRedirected() public {
        bytes memory signature = _sign(_safeMintDigest(address(this), recipient, 4, authorizationDeadline));

        vm.expectRevert("NalndaBook: Invalid signature!");
        book.safeMint(makeAddr("attacker"), 4, authorizationDeadline, signature);
    }

    function testMintSignatureCannotAuthorizeBatchMint() public {
        bytes memory signature = _sign(_safeMintDigest(address(this), recipient, 5, authorizationDeadline));
        address[] memory recipients = new address[](1);
        recipients[0] = recipient;

        vm.expectRevert("NalndaBook: Invalid signature!");
        book.batchSafeMint(recipients, 5, authorizationDeadline, signature);
    }

    function testExactMintAuthorizationSucceedsOnlyOnce() public {
        bytes memory signature = _sign(_safeMintDigest(address(this), recipient, 6, authorizationDeadline));

        book.safeMint(recipient, 6, authorizationDeadline, signature);
        assertEq(book.ownerOf(1), recipient);

        vm.expectRevert("NalndaBook: Hash has already been used!");
        book.safeMint(recipient, 6, authorizationDeadline, signature);
    }

    function testAuthorizationCannotBeUsedByDifferentCaller() public {
        bytes memory signature = _sign(_safeMintDigest(address(this), recipient, 7, authorizationDeadline));

        vm.prank(makeAddr("attacker"));
        vm.expectRevert("NalndaBook: Invalid signature!");
        book.safeMint(recipient, 7, authorizationDeadline, signature);
    }

    function testGaslessMintUsesOriginalUserAsCaller() public {
        address user = vm.addr(USER_PRIVATE_KEY);
        bytes memory authorization = _sign(_safeMintDigest(user, recipient, 8, authorizationDeadline));
        bytes memory data = abi.encodeCall(NalndaBook.safeMint, (recipient, 8, authorizationDeadline, authorization));
        uint256 gasLimit = 500_000;
        uint48 forwarderDeadline = uint48(block.timestamp + 1 hours);
        bytes32 requestDigest = _typedDataHash(
            "NalndaForwarder",
            address(forwarder),
            keccak256(
                abi.encode(
                    FORWARD_REQUEST_TYPEHASH,
                    user,
                    address(book),
                    0,
                    gasLimit,
                    forwarder.nonces(user),
                    forwarderDeadline,
                    keccak256(data)
                )
            )
        );
        ERC2771Forwarder.ForwardRequestData memory request = ERC2771Forwarder.ForwardRequestData({
            from: user,
            to: address(book),
            value: 0,
            gas: gasLimit,
            deadline: forwarderDeadline,
            data: data,
            signature: _signWithKey(USER_PRIVATE_KEY, requestDigest)
        });

        vm.prank(makeAddr("relayer"));
        forwarder.execute(request);

        assertEq(book.ownerOf(1), recipient);
    }

    function testExpiredAuthorizationIsRejected() public {
        bytes memory signature = _sign(_safeMintDigest(address(this), recipient, 9, authorizationDeadline));
        vm.warp(uint256(authorizationDeadline) + 1);

        vm.expectRevert("NalndaBook: Signature expired!");
        book.safeMint(recipient, 9, authorizationDeadline, signature);
    }

    function testAuthorizationIsValidAtDeadline() public {
        bytes memory signature = _sign(_safeMintDigest(address(this), recipient, 10, authorizationDeadline));
        vm.warp(authorizationDeadline);

        book.safeMint(recipient, 10, authorizationDeadline, signature);
        assertEq(book.ownerOf(1), recipient);
    }

    function testPauseBlocksExistingBookMintAndTransfer() public {
        vm.prank(author);
        book.ownerMint(recipient);
        marketplace.pause();

        bytes memory signature = _sign(_safeMintDigest(address(this), recipient, 11, authorizationDeadline));
        vm.expectRevert(NalndaMarketplace.MarketplacePaused.selector);
        book.safeMint(recipient, 11, authorizationDeadline, signature);

        vm.prank(recipient);
        vm.expectRevert(NalndaMarketplace.MarketplacePaused.selector);
        book.transferFrom(recipient, author, 1);
    }

    function testPauseBlocksNewMarketplaceTransactions() public {
        marketplace.pause();

        vm.expectRevert(NalndaMarketplace.MarketplacePaused.selector);
        marketplace.createNewBook(author, "ipfs://paused");
    }

    function testAnyoneCanCreateBook() public {
        address creator = makeAddr("creator");

        vm.prank(creator);
        address createdBook = marketplace.createNewBook(author, "ipfs://permissionless");

        assertEq(Ownable(createdBook).owner(), author);
        assertTrue(marketplace.createdBooks(createdBook));
        assertEq(marketplace.authorToBooks(creator, 0), createdBook);
    }

    function testOnlyMarketplaceOwnerCanPauseBook() public {
        address caller = makeAddr("caller");

        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, caller));
        marketplace.pauseBook(address(book));
    }

    function testBookPauseBlocksMintAndTransfer() public {
        vm.prank(author);
        book.ownerMint(recipient);
        marketplace.pauseBook(address(book));

        vm.prank(author);
        vm.expectRevert(NalndaBook.BookIsPaused.selector);
        book.ownerMint(author);

        vm.prank(recipient);
        vm.expectRevert(NalndaBook.BookIsPaused.selector);
        book.transferFrom(recipient, author, 1);
    }

    function testBookPauseBlocksListing() public {
        vm.prank(author);
        book.ownerMint(author);
        marketplace.pauseBook(address(book));

        vm.prank(author);
        vm.expectRevert(NalndaBook.BookIsPaused.selector);
        marketplace.listCover(book, 1, 1 ether, 12, authorizationDeadline, bytes(""));
    }

    function testBookPauseBlocksBuying() public {
        vm.prank(author);
        book.ownerMint(author);
        bytes memory listSignature = _sign(
            _typedDataHash(
                "NalndaMarketplace",
                address(marketplace),
                keccak256(abi.encode(LIST_COVER_TYPEHASH, author, address(book), 1, 1 ether, 40, authorizationDeadline))
            )
        );
        vm.prank(author);
        marketplace.listCover(book, 1, 1 ether, 40, authorizationDeadline, listSignature);
        marketplace.pauseBook(address(book));

        vm.expectRevert(NalndaBook.BookIsPaused.selector);
        marketplace.buyCover(1, 41, authorizationDeadline, bytes(""));
    }

    function testSellerCanUnlistPausedBook() public {
        vm.prank(author);
        book.ownerMint(author);
        bytes memory listSignature = _sign(
            _typedDataHash(
                "NalndaMarketplace",
                address(marketplace),
                keccak256(abi.encode(LIST_COVER_TYPEHASH, author, address(book), 1, 1 ether, 42, authorizationDeadline))
            )
        );
        vm.prank(author);
        marketplace.listCover(book, 1, 1 ether, 42, authorizationDeadline, listSignature);
        marketplace.pauseBook(address(book));
        bytes memory unlistSignature = _sign(
            _typedDataHash(
                "NalndaMarketplace",
                address(marketplace),
                keccak256(abi.encode(UNLIST_COVER_TYPEHASH, author, 1, 43, authorizationDeadline))
            )
        );

        vm.prank(author);
        marketplace.unlistCover(1, 43, authorizationDeadline, unlistSignature);

        assertEq(book.ownerOf(1), author);
    }

    function testBookCanBeUnpaused() public {
        marketplace.pauseBook(address(book));
        marketplace.unpauseBook(address(book));

        vm.prank(author);
        book.ownerMint(author);

        assertFalse(book.paused());
        assertEq(book.ownerOf(1), author);
    }

    function testBooksCanBePausedAndUnpausedInBatch() public {
        NalndaBook secondBook = NalndaBook(payable(marketplace.createNewBook(author, "ipfs://second")));
        address[] memory books = new address[](2);
        books[0] = address(book);
        books[1] = address(secondBook);

        marketplace.pauseBooks(books);
        assertTrue(book.paused());
        assertTrue(secondBook.paused());

        marketplace.unpauseBooks(books);
        assertFalse(book.paused());
        assertFalse(secondBook.paused());
    }

    function testCannotPauseUnknownBook() public {
        vm.expectRevert(NalndaMarketplace.UnknownBook.selector);
        marketplace.pauseBook(makeAddr("unknownBook"));
    }

    function testSellerCanUnlistWhilePaused() public {
        vm.prank(author);
        book.ownerMint(author);
        bytes memory listSignature = _sign(
            _typedDataHash(
                "NalndaMarketplace",
                address(marketplace),
                keccak256(abi.encode(LIST_COVER_TYPEHASH, author, address(book), 1, 1 ether, 13, authorizationDeadline))
            )
        );
        vm.prank(author);
        marketplace.listCover(book, 1, 1 ether, 13, authorizationDeadline, listSignature);
        marketplace.pause();

        bytes memory unlistSignature = _sign(
            _typedDataHash(
                "NalndaMarketplace",
                address(marketplace),
                keccak256(abi.encode(UNLIST_COVER_TYPEHASH, author, 1, 14, authorizationDeadline))
            )
        );
        vm.prank(author);
        marketplace.unlistCover(1, 14, authorizationDeadline, unlistSignature);

        assertEq(book.ownerOf(1), author);
    }

    function testUnpauseRestoresBookTransactions() public {
        marketplace.pause();
        marketplace.unpause();
        bytes memory signature = _sign(_safeMintDigest(address(this), recipient, 15, authorizationDeadline));

        book.safeMint(recipient, 15, authorizationDeadline, signature);
        assertEq(book.ownerOf(1), recipient);
    }

    function testSignerRotationImmediatelyAppliesToExistingBooks() public {
        bytes32 digest = _safeMintDigest(address(this), recipient, 16, authorizationDeadline);
        bytes memory oldSignature = _sign(digest);
        address newSigner = vm.addr(NEW_SIGNER_PRIVATE_KEY);

        vm.expectEmit(true, true, false, false);
        emit NalndaMarketplace.SignerAddressUpdated(signer, newSigner);
        marketplace.setSignerAddress(newSigner);

        vm.expectRevert("NalndaBook: Invalid signature!");
        book.safeMint(recipient, 16, authorizationDeadline, oldSignature);

        bytes memory newSignature = _signWithKey(NEW_SIGNER_PRIVATE_KEY, digest);
        book.safeMint(recipient, 16, authorizationDeadline, newSignature);
        assertEq(book.ownerOf(1), recipient);
    }

    function testSignerCannotBeSetToZeroAddress() public {
        vm.expectRevert(NalndaMarketplace.InvalidSignerAddress.selector);
        marketplace.setSignerAddress(address(0));
    }

    function testConstructorRejectsZeroSigner() public {
        NalndaMarketplace implementation = new NalndaMarketplace();
        vm.expectRevert(NalndaMarketplace.InvalidSignerAddress.selector);
        new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(NalndaMarketplace.initialize, (address(this), address(0), address(forwarder)))
        );
    }

    function testConstructorRejectsZeroOwner() public {
        NalndaMarketplace implementation = new NalndaMarketplace();
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(NalndaMarketplace.initialize, (address(0), signer, address(forwarder)))
        );
    }

    function testMarketplaceCanInitializeWithoutTrustedForwarder() public {
        NalndaMarketplace implementation = new NalndaMarketplace();
        NalndaMarketplace noForwarderMarketplace = NalndaMarketplace(
            payable(address(
                    new ERC1967Proxy(
                        address(implementation),
                        abi.encodeCall(NalndaMarketplace.initialize, (address(this), signer, address(0)))
                    )
                ))
        );

        assertEq(noForwarderMarketplace.trustedForwarder(), address(0));
        assertFalse(noForwarderMarketplace.isTrustedForwarder(address(forwarder)));
    }

    function testConstructorRejectsEOATrustedForwarder() public {
        NalndaMarketplace implementation = new NalndaMarketplace();
        vm.expectRevert(NalndaMarketplace.InvalidTrustedForwarder.selector);
        new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(NalndaMarketplace.initialize, (address(this), signer, makeAddr("fakeForwarder")))
        );
    }

    function testMarketplaceRejectsZeroTokenWithdrawalAddress() public {
        vm.expectRevert(NalndaMarketplace.InvalidTokenAddress.selector);
        marketplace.withdrawAnyERC20(address(0));
    }

    function testBookRejectsZeroTokenWithdrawalAddress() public {
        vm.prank(author);
        vm.expectRevert(NalndaBook.InvalidTokenAddress.selector);
        book.withdrawAnyERC20(address(0));
    }

    function testMintRejectsZeroRecipient() public {
        bytes memory signature = _sign(_safeMintDigest(address(this), address(0), 17, authorizationDeadline));

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        book.safeMint(address(0), 17, authorizationDeadline, signature);
    }

    function testBookProxyHasERC721NameAndSymbol() public view {
        assertEq(book.name(), "NalndaBookCover");
        assertEq(book.symbol(), "COVER");
    }

    function testTokenURIRejectsNonexistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 1));
        book.tokenURI(1);
    }

    function testListingRejectsBookNotCreatedByMarketplace() public {
        FakeBook fakeBook = new FakeBook();

        vm.expectRevert(NalndaMarketplace.UnknownBook.selector);
        marketplace.listCover(NalndaBook(payable(address(fakeBook))), 1, 1 ether, 18, authorizationDeadline, bytes(""));
    }

    function testAuthorCannotUpgradeBook() public {
        NalndaBookV2 implementation = new NalndaBookV2(address(marketplace));

        vm.prank(author);
        vm.expectRevert(NalndaBook.UnauthorizedMarketplaceOwner.selector);
        book.upgradeToAndCall(address(implementation), bytes(""));
    }

    function testMarketplaceOwnerCannotUpgradeBookWhenUnpaused() public {
        NalndaBookV2 implementation = new NalndaBookV2(address(marketplace));

        vm.expectRevert(NalndaMarketplace.MarketplaceNotPaused.selector);
        book.upgradeToAndCall(address(implementation), bytes(""));
    }

    function testMarketplaceOwnerCanUpgradeBookWhilePaused() public {
        NalndaBookV2 implementation = new NalndaBookV2(address(marketplace));
        marketplace.pause();

        book.upgradeToAndCall(address(implementation), bytes(""));
        assertEq(NalndaBookV2(address(book)).version(), 2);
    }

    function testBookUpgradeAuthorityFollowsMarketplaceOwnership() public {
        address newMarketplaceOwner = makeAddr("newMarketplaceOwner");
        NalndaBookV2 implementation = new NalndaBookV2(address(marketplace));
        marketplace.transferOwnership(newMarketplaceOwner);
        vm.prank(newMarketplaceOwner);
        marketplace.pause();

        vm.expectRevert(NalndaBook.UnauthorizedMarketplaceOwner.selector);
        book.upgradeToAndCall(address(implementation), bytes(""));

        vm.prank(newMarketplaceOwner);
        book.upgradeToAndCall(address(implementation), bytes(""));
        assertEq(NalndaBookV2(address(book)).version(), 2);
    }

    function testMarketplaceImplementationCannotBeInitialized() public {
        NalndaMarketplace implementation = new NalndaMarketplace();

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementation.initialize(address(this), signer, address(forwarder));
    }

    function testMarketplaceCannotBeInitializedTwice() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        marketplace.initialize(address(this), signer, address(forwarder));
    }

    function testOnlyMarketplaceOwnerCanUpgradeMarketplace() public {
        NalndaMarketplaceV2 implementation = new NalndaMarketplaceV2();

        vm.prank(makeAddr("attacker"));
        vm.expectRevert();
        marketplace.upgradeToAndCall(address(implementation), bytes(""));
    }

    function testMarketplaceOwnerCannotUpgradeMarketplaceWhenUnpaused() public {
        NalndaMarketplaceV2 implementation = new NalndaMarketplaceV2();

        vm.expectRevert(NalndaMarketplace.MarketplaceNotPaused.selector);
        marketplace.upgradeToAndCall(address(implementation), bytes(""));
    }

    function testMarketplaceOwnerCanUpgradeMarketplaceWhilePaused() public {
        NalndaMarketplaceV2 implementation = new NalndaMarketplaceV2();
        address previousSigner = marketplace.signerAddress();
        address previousOwner = marketplace.owner();
        marketplace.pause();

        marketplace.upgradeToAndCall(address(implementation), bytes(""));

        assertEq(NalndaMarketplaceV2(address(marketplace)).version(), 2);
        assertEq(marketplace.signerAddress(), previousSigner);
        assertEq(marketplace.owner(), previousOwner);
    }

    function testMarketplaceOwnershipCannotBeRenounced() public {
        vm.expectRevert("NalndaMarketplace: Ownership cannot be renounced!");
        marketplace.renounceOwnership();
    }

    function testForwarderRotationAppliesToExistingBooks() public {
        ERC2771Forwarder newForwarder = new ERC2771Forwarder("NalndaForwarderV2");

        vm.expectEmit(true, true, false, false);
        emit NalndaMarketplace.TrustedForwarderUpdated(address(forwarder), address(newForwarder));
        marketplace.setTrustedForwarder(address(newForwarder));

        assertEq(marketplace.trustedForwarder(), address(newForwarder));
        assertEq(book.trustedForwarder(), address(newForwarder));
        assertTrue(marketplace.isTrustedForwarder(address(newForwarder)));
        assertTrue(book.isTrustedForwarder(address(newForwarder)));
        assertFalse(marketplace.isTrustedForwarder(address(forwarder)));
        assertFalse(book.isTrustedForwarder(address(forwarder)));
    }

    function testForwarderCannotBeRotatedToInvalidAddress() public {
        vm.expectRevert(NalndaMarketplace.InvalidTrustedForwarder.selector);
        marketplace.setTrustedForwarder(makeAddr("fakeForwarder"));
    }

    function testForwarderCanBeDisabledAcrossExistingBooks() public {
        marketplace.setTrustedForwarder(address(0));

        assertEq(marketplace.trustedForwarder(), address(0));
        assertEq(book.trustedForwarder(), address(0));
        assertFalse(marketplace.isTrustedForwarder(address(forwarder)));
        assertFalse(book.isTrustedForwarder(address(forwarder)));
    }

    function _sign(bytes32 digest) private pure returns (bytes memory) {
        return _signWithKey(SIGNER_PRIVATE_KEY, digest);
    }

    function _signWithKey(uint256 privateKey, bytes32 digest) private pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }

    function _safeMintDigest(address caller, address to, uint256 nonce, uint48 deadline)
        private
        view
        returns (bytes32)
    {
        return _typedDataHash(
            "NalndaBook", address(book), keccak256(abi.encode(SAFE_MINT_TYPEHASH, caller, to, nonce, deadline))
        );
    }

    function _typedDataHash(string memory name, address verifyingContract, bytes32 structHash)
        private
        view
        returns (bytes32)
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes("1")), block.chainid, verifyingContract)
        );
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
