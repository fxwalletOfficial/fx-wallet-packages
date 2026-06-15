# FxWallet Web3 Provider

```
//   ___ ___       ___  __   ___
//  |__   |  |__| |__  |__) |__  |  |  |\/|
//  |___  |  |  | |___ |  \ |___ \__/  |  |
//
```

### Ethereum JavaScript Provider Implementation

### Config Object

```typescript
const config: {
  chainId?: string;            // hex chain id, e.g. '0x1'
  rpc?: string;                // custom RPC URL (also accepts `rpcUrl`)
  overwriteMetamask?: boolean; // make window.ethereum.isMetaMask report true
  isFxWallet?: boolean;
} = {};
```

### Usage

```typescript
const ethereum = new EthereumProvider(config);
```
