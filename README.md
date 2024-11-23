# Nalnda Smart Contracts

### Latest addresses - polygon amoy

```text
MockUSDT: 0xdB899cC0CF97f3CEC81cA0ab72C7a3189E7e4555
NalndaMarketplace deployed at: 0x66e9f29AF47f6e9a028A975B68f55dE981dDd1F4
NalndaDiscounts deployed at: 0xaa5C1918164629B464e284f8257aa683108B5697
```

#### Deploy and verify MockUSDT for testing - polygon amoy

```shell
forge script script/MockUSDT.s.sol --fork-url amoy --verify amoy --broadcast --slow
```

#### Deploy the NalndaMarketplace contract - polygon amoy

```shell
forge script script/NalndaMarketplace.s.sol --fork-url amoy --broadcast
```
