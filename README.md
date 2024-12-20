# Nalnda Smart Contracts

### Latest addresses - polygon amoy

```text
MockUSDT: 0xdB899cC0CF97f3CEC81cA0ab72C7a3189E7e4555
NalndaMarketplace deployed at: 0xEA51091383a73C510E56860f97A89be347c04a9A
NalndaDiscounts deployed at: 0xA39555647a37d6a422AeBD1300fEA25CAF76586B
```

### Latest addresses - base sepolia

```text
MockUSDT: 0x090dD4074ff85AD0e73916dA05635705250969dc
NalndaMarketplace deployed at: 0x642071d88e51ffAE9aD2694392B006425E7727Aa
NalndaDiscounts deployed at: 0xa9A128E125C07D2b51bBf85CFA59156B4143E6b6
```

#### Deploy and verify MockUSDT for testing

```shell
forge script script/MockUSDT.s.sol --fork-url [NETWORK_ALIAS] --verify amoy --broadcast --slow
```

#### Deploy the NalndaMarketplace contract

```shell
forge script script/NalndaMarketplace.s.sol --fork-url [NETWORK_ALIAS] --broadcast
```
