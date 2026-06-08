# FxWallet Web3 Provider

```

//   __   __
//  /__` /  \ |     /\  |\ |  /\
//  .__/ \__/ |___ /~~\ | \| /~~\
//

```

### Solana JavaScript Provider Implementation that uses Wallet Standard

### Config Object

```typescript
const config: {
  isFxWallet?: boolean;
  enableAdapter?: boolean;
  cluster?: string;
  disableMobileAdapter?: boolean;
} = {};
```

### Usage

```typescript
const solana = new SolanaProvider(config);
```
