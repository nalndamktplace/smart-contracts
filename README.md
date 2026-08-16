# Nalnda Smart Contracts

### Latest addresses - base sepolia

```text
NalndaMarketplace implementation deployed at: 0x9Ef594f8791202e9f0B6Fa575d1701CC9E9262aE
NalndaMarketplace deployed at: 0xa2aEe69f8c15C3757c6ad8032d4Ab4E99E4a7837
NalndaSCW implementation deployed at: 0x09358EF316C673b02EA34e0f1b0e38e8848A2731
NalndaSCWFactory deployed at: 0x3eb3B6537b725a3Ec6F0aabc6EF5cfCE39eFd692
```

### Legacy addresses - polygon amoy

```text
MockUSDT: 0xdB899cC0CF97f3CEC81cA0ab72C7a3189E7e4555
NalndaMarketplace deployed at: 0xEA51091383a73C510E56860f97A89be347c04a9A
NalndaDiscounts deployed at: 0xA39555647a37d6a422AeBD1300fEA25CAF76586B
```

### Legacy addresses - base sepolia

```text
MockUSDT: 0x090dD4074ff85AD0e73916dA05635705250969dc
NalndaMarketplace deployed at: 0x642071d88e51ffAE9aD2694392B006425E7727Aa
NalndaDiscounts deployed at: 0xa9A128E125C07D2b51bBf85CFA59156B4143E6b6
```

#### Deploy the Nalnda contracts

The script deploys `NalndaSCWFactory` and its implementation. The smart contract wallet uses account-abstraction v0.7 and Alchemy's EntryPoint at `0x0000000071727De22E5E9d8BAf0edAc6f37da032`.

The default deployment disables ERC-2771 forwarding by setting the trusted forwarder to `address(0)`. Direct calls and ERC-4337 UserOperations do not require an ERC-2771 forwarder. The marketplace owner can enable one later with `setTrustedForwarder`.

```shell
forge script script/NalndaMarketplace.s.sol --fork-url [NETWORK_ALIAS] --broadcast
```
