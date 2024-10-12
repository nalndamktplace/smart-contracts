# Nalnda Smart Contracts

### Latest addresses - polygon amoy

```text
MockUSDT: 0xdB899cC0CF97f3CEC81cA0ab72C7a3189E7e4555
NalndaMarketplace: 0x585bE5C209F3A0233FA9ed269CDEd41Ab646b51e
```

#### Deploy and verify MockUSDT for testing - polygon amoy

```shell
forge script script/MockUSDT.s.sol --fork-url amoy --verify amoy --broadcast --slow
```

#### Deploy the NalndaMarketplace contract - polygon amoy

```shell
forge script script/NalndaMarketplace.s.sol --fork-url amoy --broadcast
```
