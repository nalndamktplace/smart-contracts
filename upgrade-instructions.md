# Upgrade Instructions

This document describes how to safely upgrade `NalndaMarketplace` and `NalndaBook` UUPS proxies.

## Architecture

The deployment contains four kinds of addresses:

| Component | Upgradeable | Purpose |
| --- | --- | --- |
| Optional `ERC2771Forwarder` | No | Verifies ERC-2771 gasless requests when enabled |
| Marketplace implementation | Replaced during upgrades | Contains marketplace logic and the implementation used for future books |
| Marketplace `ERC1967Proxy` | Permanent address | Stores marketplace state and delegates to the marketplace implementation |
| Book `ERC1967Proxy` | Permanent address per book | Stores NFT state and delegates to a book implementation |

Applications and users must always interact with proxy addresses, not implementation addresses.

The current marketplace proxy address remains unchanged after a marketplace upgrade. Each book proxy address also remains unchanged after a book upgrade.

## Upgrade Authority

Only the current marketplace owner can upgrade either the marketplace or a book.

- Marketplace upgrades use `NalndaMarketplace._authorizeUpgrade()`.
- Book upgrades dynamically require `marketplaceContract.owner()`.
- Transferring marketplace ownership transfers upgrade authority for the marketplace and all existing books.
- Marketplace ownership cannot be renounced.

Use a multisig as the marketplace owner in production. Do not use the backend signing key as the marketplace owner key.

## Pause Requirement

The marketplace must be paused before upgrading the marketplace or any book.

```solidity
marketplace.pause();
```

Upgrades revert with `MarketplaceNotPaused()` while the system is unpaused.

After completing and verifying all upgrades:

```solidity
marketplace.unpause();
```

Keep the system paused if post-upgrade verification fails.

## Storage Layout Rules

UUPS upgrades replace executable code but retain proxy storage. A new implementation must interpret every existing storage slot exactly as the previous implementation did.

Never:

- Reorder existing state variables.
- Remove existing state variables.
- Change an existing variable's type.
- Change inheritance order when inherited contracts contain storage.
- Insert a new storage-bearing parent contract.
- Insert new variables between existing variables.
- Replace OpenZeppelin storage-bearing base contracts without proving layout compatibility.

Append new state variables only after all current variables.

Constants and immutables do not occupy proxy storage. They may be changed by deploying a new implementation, but their behavioral impact must be reviewed.

### Marketplace Storage Layout

The current marketplace layout is:

| Slot | Offset | Variable | Type |
| --- | --- | --- | --- |
| 0 | 0 | `Ownable._owner` | `address` |
| 1 | 0 | `authorToBooks` | `mapping(address => address[])` |
| 2 | 0 | `totalBooksCreated` | `uint256` |
| 3 | 0 | `lastOrderId` | `uint256` |
| 4 | 0 | `ORDER` | `mapping(uint256 => Order)` |
| 5 | 0 | `createdBooks` | `mapping(address => bool)` |
| 6 | 0 | `extraSalt` | `uint256` |
| 7 | 0 | `authorizedBookCreator` | `address` |
| 8 | 0 | `signerAddress` | `address` |
| 8 | 20 | `paused` | `bool` |
| 9 | 0 | `executed` | `mapping(bytes32 => bool)` |
| 10 | 0 | `trustedForwarder` | `address` |

New marketplace storage must be appended after `trustedForwarder`. Solidity may pack a sufficiently small new variable into unused bytes in slot 10; avoid relying on manual packing assumptions and verify the compiler-produced layout.

### Book Storage Layout

The current book layout is:

| Slot | Offset | Variable | Type |
| --- | --- | --- | --- |
| 0 | 0 | `ERC721._name` | `string` |
| 1 | 0 | `ERC721._symbol` | `string` |
| 2 | 0 | `ERC721._owners` | `mapping(uint256 => address)` |
| 3 | 0 | `ERC721._balances` | `mapping(address => uint256)` |
| 4 | 0 | `ERC721._tokenApprovals` | `mapping(uint256 => address)` |
| 5 | 0 | `ERC721._operatorApprovals` | `mapping(address => mapping(address => bool))` |
| 6 | 0 | `Ownable._owner` | `address` |
| 7 | 0 | `executed` | `mapping(bytes32 => bool)` |
| 8 | 0 | `_nextTokenId` | `uint256` |
| 9 | 0 | `marketplaceContract` | `NalndaMarketplace` |
| 9 | 20 | `approved` | `bool` |
| 10 | 0 | `daysForSecondarySales` | `uint256` |
| 11 | 0 | `secondarySalesTimestamp` | `uint256` |
| 12 | 0 | `bookLang` | `uint256` |
| 13 | 0 | `bookGenre` | `uint256[]` |
| 14 | 0 | `uri` | `string` |
| 15 | 0 | `mintPrice` | `uint256` |
| 16 | 0 | `lastSoldPrice` | `mapping(uint256 => uint256)` |
New book storage must begin after slot 16.

### Checking Layouts

Generate layouts before and after modifying contracts:

```shell
forge clean
forge build
forge inspect NalndaMarketplace storage-layout
forge inspect NalndaBook storage-layout
```

Save the old output and compare every existing variable's slot, offset, and type. Do not proceed if any existing entry changes.

Tests that merely deploy a fresh proxy cannot detect storage corruption. Upgrade tests must populate state in the old implementation, perform the upgrade, and verify that the state is unchanged.

## Immutables

### Marketplace Immutables

The marketplace implementation contains:

- `book_implementation`
- `chainId`

These values belong to the implementation bytecode, not marketplace proxy storage.

After upgrading the marketplace:

- `chainId()` is read from the new marketplace implementation.
- `book_implementation()` points to the `NalndaBook` implementation deployed by the new marketplace implementation's constructor.
- New books use the new `book_implementation`.
- Existing books continue using their current implementations until upgraded individually.

Deploy marketplace implementations on the same chain as the proxy. Do not deploy an implementation on one chain and attempt to reuse its address assumptions on another chain.

### Book Immutables

Each book implementation contains `chainId` in its bytecode. All book proxies using that implementation read the implementation's immutable value.

EIP-712 authorization security uses live `block.chainid` and the proxy address, not the stored immutable `chainId`.

## Trusted Forwarder

ERC-2771 forwarding is optional. A zero trusted-forwarder address disables ERC-2771 and makes contracts use normal `msg.sender` behavior. This is appropriate for direct calls and ERC-4337 UserOperations, where the smart account itself calls the marketplace or book.

Do not configure an ERC-4337 EntryPoint, bundler, or paymaster as an ERC-2771 trusted forwarder.

The trusted ERC-2771 forwarder is marketplace storage and can be enabled, disabled, or rotated without upgrading contracts:

```solidity
marketplace.setTrustedForwarder(newForwarder);
```

Disable ERC-2771:

```solidity
marketplace.setTrustedForwarder(address(0));
```

Requirements:

- A nonzero new address must contain contract code.
- Zero explicitly disables ERC-2771 forwarding.
- Only the marketplace owner can rotate it.

Every existing book dynamically reads `marketplaceContract.trustedForwarder()`. Rotation therefore takes effect immediately for the marketplace and all existing books.

After enabling or rotating:

- Stop sending requests through the old forwarder.
- Update relayer configuration and frontend EIP-712 domains.
- Confirm `marketplace.isTrustedForwarder(newForwarder)`.
- Confirm `book.isTrustedForwarder(newForwarder)` on representative existing books.

Forwarder rotation is separate from signer rotation. The forwarder verifies user gasless requests; `signerAddress` verifies backend operation authorizations.

The default deployment script initializes `trustedForwarder` to zero and does not deploy a forwarder. Enable one later only after selecting and verifying an ERC-2771-compatible service contract for the target chain.

## Marketplace Upgrade Procedure

### 1. Implement the New Version

Inherit the current marketplace implementation:

```solidity
contract NalndaMarketplaceV2 is NalndaMarketplace {
    uint256 public newValue;

    function initializeV2(uint256 value) external reinitializer(2) {
        newValue = value;
    }
}
```

The base marketplace constructor takes no arguments. It disables implementation initialization and deploys the book implementation used by future books.

Use `reinitializer(2)` only when the upgrade needs to initialize newly appended storage. Increase the version for later upgrades, such as `reinitializer(3)`.

If a reinitializer is required, include it atomically in the `upgradeToAndCall` transaction. Do not upgrade with empty data and plan to initialize in a later transaction; another account could call an insufficiently protected reinitializer first.

Never call the original `initialize()` during an upgrade.

### 2. Verify Locally

```shell
forge clean
forge fmt --check
forge build
forge test
forge build --sizes
forge inspect NalndaMarketplace storage-layout
forge inspect NalndaBook storage-layout
git diff --check
```

The marketplace runtime must remain below 24,576 bytes. Initcode must remain below 49,152 bytes on chains enforcing EIP-3860.

### 3. Test Against a Fork

Fork the target network and use the real marketplace proxy address. At minimum verify:

- `owner()`
- `signerAddress()`
- `trustedForwarder()`
- `paused()`
- `totalBooksCreated()`
- `lastOrderId()`
- Representative `ORDER` entries
- Representative `createdBooks` entries
- Representative replay entries in `executed`
- Existing book ownership, balances, and metadata

Populate or identify active orders before upgrading and verify they remain unchanged afterward.

### 4. Pause

From the marketplace owner multisig:

```solidity
marketplace.pause();
```

Confirm:

```solidity
marketplace.paused() == true
```

### 5. Deploy the New Implementation

Deploy only the implementation. Do not deploy another marketplace proxy.

Example Foundry script logic:

```solidity
NalndaMarketplaceV2 implementation = new NalndaMarketplaceV2();
```

Do not call `initialize()` on the implementation. Its initializers are disabled by its constructor.

### 6. Upgrade the Existing Proxy

Without new initialization:

```solidity
marketplace.upgradeToAndCall(address(implementation), bytes(""));
```

With V2 initialization:

```solidity
marketplace.upgradeToAndCall(
    address(implementation),
    abi.encodeCall(NalndaMarketplaceV2.initializeV2, (value))
);
```

The caller must be the marketplace owner and the marketplace must be paused.

### 7. Verify Before Unpausing

Confirm the implementation slot points to the expected address and verify all state listed in step 3.

The ERC-1967 implementation slot is:

```text
0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

Read it with an RPC client or explorer proxy interface. The final 20 bytes are the implementation address.

Also verify:

- New V2 functions work.
- Old signatures still follow the intended policy.
- Signer rotation still affects existing books.
- Forwarder resolution still matches the marketplace.
- Existing orders can be unlisted while paused.
- Newly created books would use the expected `book_implementation` after unpause.

### 8. Verify Source Code

Verify the new implementation on the block explorer. Update the proxy's implementation association if the explorer does not detect it automatically.

### 9. Unpause

Only after all checks pass:

```solidity
marketplace.unpause();
```

## Book Upgrade Procedure

Books are upgraded one proxy at a time. Upgrading the marketplace does not upgrade existing books.

### 1. Implement the New Book Version

```solidity
contract NalndaBookV2 is NalndaBook {
    uint256 public newBookValue;

    constructor(address initialOwner) NalndaBook(initialOwner) {}

    function initializeV2(uint256 value) external reinitializer(2) {
        newBookValue = value;
    }
}
```

The constructor argument initializes only implementation-contract ownership and satisfies the base constructor. It does not change proxy ownership. A practical deployment value is the marketplace proxy address.

If the book upgrade requires `initializeV2`, execute it atomically through `upgradeToAndCall` rather than in a later transaction.

### 2. Verify Book Storage Compatibility

Run:

```shell
forge clean
forge build
forge inspect NalndaBook storage-layout
```

Ensure all slots through `lastSoldPrice` remain unchanged and new variables are appended.

### 3. Pause the Marketplace

```solidity
marketplace.pause();
```

Book upgrades revert while the marketplace is unpaused.

### 4. Deploy the Book Implementation

```solidity
NalndaBookV2 implementation = new NalndaBookV2(address(marketplace));
```

One implementation can be used to upgrade multiple compatible book proxies.

### 5. Upgrade Each Book Proxy

Without additional initialization:

```solidity
book.upgradeToAndCall(address(implementation), bytes(""));
```

With V2 initialization:

```solidity
book.upgradeToAndCall(
    address(implementation),
    abi.encodeCall(NalndaBookV2.initializeV2, (value))
);
```

The transaction caller must be the marketplace owner. The book author cannot upgrade the book.

For many books, use a reviewed batch executor or multisig batch. A failure should not leave the system unpaused with only part of the fleet upgraded.

### 6. Verify Each Book

For every upgraded proxy, verify:

- `owner()` remains the author.
- `marketplaceContract()` remains the marketplace proxy.
- `name()` returns `NalndaBookCover`.
- `symbol()` returns `COVER`.
- `uri()` and `tokenURI()` are unchanged.
- `coverIdCounter()` is unchanged.
- Representative `ownerOf()` and `balanceOf()` values are unchanged.
- `approved`, language, genre, price, and last-sale values are unchanged.
- `trustedForwarder()` equals `marketplace.trustedForwarder()`.
- Transfers and minting remain blocked while paused.

### 7. Unpause After the Fleet Is Ready

```solidity
marketplace.unpause();
```

## Rollback

UUPS has no automatic rollback. Rolling back means upgrading the proxy to another UUPS-compatible implementation.

Before an upgrade:

- Keep the previous implementation address.
- Keep its verified source and build configuration.
- Confirm it remains UUPS-compatible.
- Prepare a rollback transaction before executing the upgrade.

If the new implementation is faulty but still permits upgrades, keep the marketplace paused and call `upgradeToAndCall()` with the previous implementation.

Do not roll back after a V2 initializer has written new state unless the previous implementation safely ignores that appended state. Never roll back if the upgrade changed existing storage semantics.

A bad implementation can permanently brick upgrades. Review `_authorizeUpgrade`, `proxiableUUID`, and storage compatibility before deployment.

## Signature Compatibility

EIP-712 domains are:

Marketplace:

```text
name: NalndaMarketplace
version: 1
chainId: live chain ID
verifyingContract: marketplace proxy address
```

Book:

```text
name: NalndaBook
version: 1
chainId: live chain ID
verifyingContract: book proxy address
```

Upgrading an implementation does not change the verifying contract because the proxy address remains unchanged.

Changing a type string, domain name, or domain version invalidates compatibility with existing backend signing code. If intentionally changing the domain version, update the backend atomically and expect old signatures to become invalid.

Signer rotation is independent of implementation upgrades:

```solidity
marketplace.setSignerAddress(newSigner);
```

All existing books read the marketplace signer dynamically.

## Production Checklist

Before upgrading:

- Marketplace owner is a secure multisig.
- New implementation source has been reviewed.
- Storage layouts have been compared.
- Upgrade and rollback have been tested on a fork.
- All tests pass.
- Runtime and initcode sizes are below network limits.
- New implementation uses the expected compiler and optimizer settings.
- New initializer uses the correct `reinitializer` version.
- Previous implementation address is recorded.
- New implementation address is verified.
- Relayer and backend teams know whether signatures or calldata change.
- Marketplace is paused.

After upgrading:

- Implementation slot matches the expected address.
- Owner, signer, forwarder, pause state, counters, and orders are unchanged.
- Existing book state is unchanged.
- New functions and initializer state are correct.
- Proxy and implementation are verified on the explorer.
- Monitoring shows no unexpected events or reverts.
- Marketplace is unpaused only after verification.

## Commands Reference

```shell
# Format and compile
forge fmt --check
forge build

# Run tests
forge test -vv

# Check deployability limits
forge build --sizes

# Inspect storage
forge inspect NalndaMarketplace storage-layout
forge inspect NalndaBook storage-layout

# Check patch whitespace
git diff --check
```

The repository uses Solidity `0.8.36`, IR compilation, optimization, and 200 optimizer runs as configured in `foundry.toml`. Use the same settings when reproducing deployment bytecode and explorer verification.
