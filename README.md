# Nalnda Smart Contracts

### Latest addresses - base sepolia

```text
NalndaMarketplace deployed at: 0x771bf76fAC40935e6525572341407e417245F649
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

#### Deploy the NalndaMarketplace contract

The default deployment disables ERC-2771 forwarding by setting the trusted forwarder to `address(0)`. Direct calls and ERC-4337 UserOperations do not require an ERC-2771 forwarder. The marketplace owner can enable one later with `setTrustedForwarder`.

```shell
forge script script/NalndaMarketplace.s.sol --fork-url [NETWORK_ALIAS] --broadcast
```
