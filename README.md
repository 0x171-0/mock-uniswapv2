
# Implement SimpleSwap
Implement a simple AMM swap (0% fee ratio) contract in `contracts/SimpleSwap.sol`. You must override all the external functions of `ISimpleSwap.sol`, and pass all the tests in `test/SimpleSwap.spec.ts`.

Suggest reading the `natSpec` of `ISimpleSwap.sol` first and then implementing the contract. If you are not sure what the function is about, feel free to discuss it in the Discord channel.


## Steps for Local Development
You need Node.js 16+ to build. Use [nvm](https://github.com/nvm-sh/nvm) to install it.

```bash
nvm use 16
npm install
npm run build
npm run test

```

# References
##### [Fork from AppWorks-School-Blockchain-Resource](https://github.com/AppWorks-School/Blockchain-Resource)

- UniswapV2-core: <https://github.com/Uniswap/v2-core>
- UniswapV2-periphery: <https://github.com/Uniswap/v2-periphery>
