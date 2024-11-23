# Nalnda Smart Contracts

### Latest addresses - polygon amoy

```text
MockUSDT: 0xdB899cC0CF97f3CEC81cA0ab72C7a3189E7e4555
NalndaMarketplace deployed at: 0xEA51091383a73C510E56860f97A89be347c04a9A
NalndaDiscounts deployed at: 0xA39555647a37d6a422AeBD1300fEA25CAF76586B
```

#### Deploy and verify MockUSDT for testing - polygon amoy

```shell
forge script script/MockUSDT.s.sol --fork-url amoy --verify amoy --broadcast --slow
```

#### Deploy the NalndaMarketplace contract - polygon amoy

```shell
forge script script/NalndaMarketplace.s.sol --fork-url amoy --broadcast
```
