const arbitrumBridgeAbi = [
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "caller",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "destination",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "uniqueId",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "batchNumber",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "indexInBatch",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "arbBlockNum",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "ethBlockNum",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "timestamp",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "callvalue",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }
    ],
    "name": "L2ToL1Transaction",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "caller",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "destination",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "hash",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "position",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "arbBlockNum",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "ethBlockNum",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "timestamp",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "callvalue",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }
    ],
    "name": "L2ToL1Tx",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "reserved",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "hash",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "position",
        "type": "uint256"
      }
    ],
    "name": "SendMerkleUpdate",
    "type": "event"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "arbBlockNum", "type": "uint256"}
    ],
    "name": "arbBlockHash",
    "outputs": [
      {"internalType": "bytes32", "name": "", "type": "bytes32"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "arbBlockNumber",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "arbChainID",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "arbOSVersion",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getStorageGasAvailable",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "isTopLevelCall",
    "outputs": [
      {"internalType": "bool", "name": "", "type": "bool"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "sender", "type": "address"},
      {"internalType": "address", "name": "unused", "type": "address"}
    ],
    "name": "mapL1SenderContractAddressToL2Alias",
    "outputs": [
      {"internalType": "address", "name": "", "type": "address"}
    ],
    "stateMutability": "pure",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "myCallersAddressWithoutAliasing",
    "outputs": [
      {"internalType": "address", "name": "", "type": "address"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "sendMerkleTreeState",
    "outputs": [
      {"internalType": "uint256", "name": "size", "type": "uint256"},
      {"internalType": "bytes32", "name": "root", "type": "bytes32"},
      {"internalType": "bytes32[]", "name": "partials", "type": "bytes32[]"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "destination", "type": "address"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "sendTxToL1",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "wasMyCallersAddressAliased",
    "outputs": [
      {"internalType": "bool", "name": "", "type": "bool"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "destination", "type": "address"}
    ],
    "name": "withdrawEth",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "_logic", "type": "address"},
      {"internalType": "address", "name": "admin_", "type": "address"},
      {"internalType": "bytes", "name": "_data", "type": "bytes"}
    ],
    "stateMutability": "payable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "previousAdmin",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "newAdmin",
        "type": "address"
      }
    ],
    "name": "AdminChanged",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "implementation",
        "type": "address"
      }
    ],
    "name": "Upgraded",
    "type": "event"
  },
  {"stateMutability": "payable", "type": "fallback"},
  {
    "inputs": [],
    "name": "admin",
    "outputs": [
      {"internalType": "address", "name": "admin_", "type": "address"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "newAdmin", "type": "address"}
    ],
    "name": "changeAdmin",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "implementation",
    "outputs": [
      {"internalType": "address", "name": "implementation_", "type": "address"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "newImplementation",
        "type": "address"
      }
    ],
    "name": "upgradeTo",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "newImplementation",
        "type": "address"
      },
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "upgradeToAndCall",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {"stateMutability": "payable", "type": "receive"},
  {
    "inputs": [
      {"internalType": "uint256", "name": "_maxDataSize", "type": "uint256"}
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "dataLength", "type": "uint256"},
      {"internalType": "uint256", "name": "maxDataLength", "type": "uint256"}
    ],
    "name": "DataTooLarge",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "GasLimitTooLarge",
    "type": "error"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "expected", "type": "uint256"},
      {"internalType": "uint256", "name": "actual", "type": "uint256"}
    ],
    "name": "InsufficientSubmissionCost",
    "type": "error"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "expected", "type": "uint256"},
      {"internalType": "uint256", "name": "actual", "type": "uint256"}
    ],
    "name": "InsufficientValue",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "L1Forked",
    "type": "error"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "origin", "type": "address"}
    ],
    "name": "NotAllowedOrigin",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "NotCodelessOrigin",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "NotForked",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "NotOrigin",
    "type": "error"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "sender", "type": "address"},
      {"internalType": "address", "name": "owner", "type": "address"}
    ],
    "name": "NotOwner",
    "type": "error"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "sender", "type": "address"},
      {"internalType": "address", "name": "rollup", "type": "address"},
      {"internalType": "address", "name": "owner", "type": "address"}
    ],
    "name": "NotRollupOrOwner",
    "type": "error"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "from", "type": "address"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "l2CallValue", "type": "uint256"},
      {"internalType": "uint256", "name": "deposit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxSubmissionCost", "type": "uint256"},
      {"internalType": "address", "name": "excessFeeRefundAddress", "type": "address"},
      {"internalType": "address", "name": "callValueRefundAddress", "type": "address"},
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "RetryableData",
    "type": "error"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "bool",
        "name": "val",
        "type": "bool"
      }
    ],
    "name": "AllowListAddressSet",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "bool",
        "name": "isEnabled",
        "type": "bool"
      }
    ],
    "name": "AllowListEnabledUpdated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "messageNum",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }
    ],
    "name": "InboxMessageDelivered",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "messageNum",
        "type": "uint256"
      }
    ],
    "name": "InboxMessageDeliveredFromOrigin",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint8",
        "name": "version",
        "type": "uint8"
      }
    ],
    "name": "Initialized",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "Paused",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "Unpaused",
    "type": "event"
  },
  {
    "inputs": [],
    "name": "allowListEnabled",
    "outputs": [
      {"internalType": "bool", "name": "", "type": "bool"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "bridge",
    "outputs": [
      {"internalType": "contract IBridge", "name": "", "type": "address"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "dataLength", "type": "uint256"},
      {"internalType": "uint256", "name": "baseFee", "type": "uint256"}
    ],
    "name": "calculateRetryableSubmissionFee",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "l2CallValue", "type": "uint256"},
      {"internalType": "uint256", "name": "maxSubmissionCost", "type": "uint256"},
      {"internalType": "address", "name": "excessFeeRefundAddress", "type": "address"},
      {"internalType": "address", "name": "callValueRefundAddress", "type": "address"},
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "createRetryableTicket",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "l2CallValue", "type": "uint256"},
      {"internalType": "uint256", "name": "maxSubmissionCost", "type": "uint256"},
      {"internalType": "address", "name": "excessFeeRefundAddress", "type": "address"},
      {"internalType": "address", "name": "callValueRefundAddress", "type": "address"},
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "createRetryableTicketNoRefundAliasRewrite",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "name": "depositEth",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "depositEth",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getProxyAdmin",
    "outputs": [
      {"internalType": "address", "name": "", "type": "address"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "contract IBridge", "name": "_bridge", "type": "address"},
      {"internalType": "contract ISequencerInbox", "name": "_sequencerInbox", "type": "address"}
    ],
    "name": "initialize",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "", "type": "address"}
    ],
    "name": "isAllowed",
    "outputs": [
      {"internalType": "bool", "name": "", "type": "bool"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "maxDataSize",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "pause",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "paused",
    "outputs": [
      {"internalType": "bool", "name": "", "type": "bool"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "contract IBridge", "name": "", "type": "address"}
    ],
    "name": "postUpgradeInit",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "value", "type": "uint256"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "sendContractTransaction",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "sendL1FundedContractTransaction",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "uint256", "name": "nonce", "type": "uint256"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "sendL1FundedUnsignedTransaction",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "uint256", "name": "nonce", "type": "uint256"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "sendL1FundedUnsignedTransactionToFork",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "bytes", "name": "messageData", "type": "bytes"}
    ],
    "name": "sendL2Message",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "bytes", "name": "messageData", "type": "bytes"}
    ],
    "name": "sendL2MessageFromOrigin",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "uint256", "name": "nonce", "type": "uint256"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "value", "type": "uint256"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "sendUnsignedTransaction",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "uint256", "name": "nonce", "type": "uint256"},
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "value", "type": "uint256"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "sendUnsignedTransactionToFork",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "uint256", "name": "nonce", "type": "uint256"},
      {"internalType": "uint256", "name": "value", "type": "uint256"},
      {"internalType": "address", "name": "withdrawTo", "type": "address"}
    ],
    "name": "sendWithdrawEthToFork",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "sequencerInbox",
    "outputs": [
      {"internalType": "contract ISequencerInbox", "name": "", "type": "address"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address[]", "name": "user", "type": "address[]"},
      {"internalType": "bool[]", "name": "val", "type": "bool[]"}
    ],
    "name": "setAllowList",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "bool", "name": "_allowListEnabled", "type": "bool"}
    ],
    "name": "setAllowListEnabled",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "unpause",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "l2CallValue", "type": "uint256"},
      {"internalType": "uint256", "name": "maxSubmissionCost", "type": "uint256"},
      {"internalType": "address", "name": "excessFeeRefundAddress", "type": "address"},
      {"internalType": "address", "name": "callValueRefundAddress", "type": "address"},
      {"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
      {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
      {"internalType": "bytes", "name": "data", "type": "bytes"}
    ],
    "name": "unsafeCreateRetryableTicket",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "payable",
    "type": "function"
  }
];
