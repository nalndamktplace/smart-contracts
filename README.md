# Nalnda Smart Contracts

### Latest addresses - polygon amoy

```text
MockUSDT: 0xdB899cC0CF97f3CEC81cA0ab72C7a3189E7e4555
NalndaMarketplace: 0x0A1e70Ff48E9E62382fDB4882d2071DD3D1b2ef8
NalndaDiscounts: 0x9191930AEe28f15019EbAD8998C71D0876849a69
```

#### Deploy and verify MockUSDT for testing - polygon amoy

```shell
forge script script/MockUSDT.s.sol --fork-url amoy --verify amoy --broadcast --slow
```

#### Deploy the NalndaMarketplace contract - polygon amoy

```shell
forge script script/NalndaMarketplace.s.sol --fork-url amoy --broadcast
```
