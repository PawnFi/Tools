# Tools

Solidity contracts used in [Pawnfi](https://pawnfi.com/) .

## Overview

The Tools contract represents a suite of peripheral tool contracts serving Pawnfi protocol.

## Audits

- PeckShield ( - ) : [report](./audits/audits.pdf) (Also available in Chinese in the same folder)

## Contracts

### Installation

- To run tools, pull the repository from GitHub and install its dependencies. You will need [npm](https://docs.npmjs.com/cli/install) installed.

```bash
git clone https://github.com/PawnFi/Tools.git
cd Tools
npm install 
```
- Create an enviroment file named `.env` and fill the next enviroment variables

```
# Import private key
PRIVATEKEY= your private key 

# Add Infura provider keys
MAINNET_NETWORK=https://mainnet.infura.io/v3/YOUR_API_KEY
GOERLI_NETWORK=https://goerli.infura.io/v3/YOUR_API_KEY

```

### Compile

```
npx hardhat compile
```



### Local deployment

In order to deploy this code to a local testnet, you should install the npm package `@pawnfi/tools` and import the NftTransferManager bytecode located at `@pawnfi/tools/artifacts/contracts/NftTransferManager.sol/NftTransferManager.json`.
For example:

```typescript
import {
  abi as TRANSFERMANAGER_ABI,
  bytecode as TRANSFERMANAGER_BYTECODE,
} from '@pawnfi/tools/artifacts/contracts/NftTransferManager.sol/NftTransferManager.json'

// deploy the bytecode
```

This will ensure that you are testing against the same bytecode that is deployed to
mainnet and public testnets, and all Pawnfi code will correctly interoperate with
your local deployment.

### Using solidity interfaces

The Pawnfi dao interfaces are available for import into solidity smart contracts
via the npm artifact `@pawnfi/tools`, e.g.:

```solidity
import '@pawnfi/tools/contracts/interfaces/INftTransferManager.sol';

contract MyContract {
  INftTransferManager transferManager;

  function doSomethingWithTransferManager() {
    // transferManager.transferNft(...);
  }
}

```

## Discussion

For any concerns with the protocol, open an issue or visit us on [Discord](https://discord.com/invite/pawnfi) to discuss.

For security concerns, please email [support@security.pawnfi.com](mailto:support@security.pawnfi.com).

_© Copyright 2023, Pawnfi Ltd._

