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
import type { WalletIcon } from '@wallet-standard/base';

const config: {
  isFxWallet?: boolean;
  enableAdapter?: boolean;     // register with the Solana wallet standard
  cluster?: string;            // RPC cluster URL for the connection
  solana?: {
    name?: string;             // wallet display name
    icon?: WalletIcon;         // complete image data URI
  };
} = {};
```

### Usage

```typescript
const solana = new SolanaProvider(config);
```

Set `config.solana.name` and `config.solana.icon` to customize the registered
wallet. Icons must be complete image data URIs, such as
`data:image/png;base64,...`, rather than image paths.

When using this JavaScript provider directly, omitted metadata defaults to
the name `FxWallet` and the built-in FxWallet icon. The Flutter wrapper
supplies its own defaults through `Web3Settings`: `Web3Wallet` for the name
and the built-in FxWallet icon for both chains.
