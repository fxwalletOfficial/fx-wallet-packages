const relayBridgeAbi = [
  {
    "inputs": [
      {"internalType": "address", "name": "_owner", "type": "address"},
      {"internalType": "address", "name": "_allocator", "type": "address"}
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {"inputs": [], "name": "AddressCannotBeZero", "type": "error"},
  {"inputs": [], "name": "AlreadyInitialized", "type": "error"},
  {
    "inputs": [
      {"internalType": "bytes", "name": "returnData", "type": "bytes"}
    ],
    "name": "CallFailed",
    "type": "error"
  },
  {"inputs": [], "name": "CallRequestAlreadyUsed", "type": "error"},
  {"inputs": [], "name": "CallRequestExpired", "type": "error"},
  {"inputs": [], "name": "InvalidSignature", "type": "error"},
  {"inputs": [], "name": "NewOwnerIsZeroAddress", "type": "error"},
  {"inputs": [], "name": "NoHandoverRequest", "type": "error"},
  {"inputs": [], "name": "Unauthorized", "type": "error"},
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "pendingOwner",
        "type": "address"
      }
    ],
    "name": "OwnershipHandoverCanceled",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "pendingOwner",
        "type": "address"
      }
    ],
    "name": "OwnershipHandoverRequested",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "oldOwner",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "OwnershipTransferred",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "bytes32",
        "name": "id",
        "type": "bytes32"
      },
      {
        "components": [
          {"internalType": "address", "name": "to", "type": "address"},
          {"internalType": "bytes", "name": "data", "type": "bytes"},
          {"internalType": "uint256", "name": "value", "type": "uint256"},
          {"internalType": "bool", "name": "allowFailure", "type": "bool"}
        ],
        "indexed": false,
        "internalType": "struct Call",
        "name": "call",
        "type": "tuple"
      }
    ],
    "name": "RelayCallExecuted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "token",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "bytes32",
        "name": "id",
        "type": "bytes32"
      }
    ],
    "name": "RelayErc20Deposit",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "bytes32",
        "name": "id",
        "type": "bytes32"
      }
    ],
    "name": "RelayNativeDeposit",
    "type": "event"
  },
  {
    "inputs": [],
    "name": "_CALL_REQUEST_TYPEHASH",
    "outputs": [
      {"internalType": "bytes32", "name": "", "type": "bytes32"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "_CALL_TYPEHASH",
    "outputs": [
      {"internalType": "bytes32", "name": "", "type": "bytes32"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "allocator",
    "outputs": [
      {"internalType": "address", "name": "", "type": "address"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "bytes32", "name": "", "type": "bytes32"}
    ],
    "name": "callRequests",
    "outputs": [
      {"internalType": "bool", "name": "", "type": "bool"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "cancelOwnershipHandover",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "pendingOwner", "type": "address"}
    ],
    "name": "completeOwnershipHandover",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "depositor", "type": "address"},
      {"internalType": "address", "name": "token", "type": "address"},
      {"internalType": "bytes32", "name": "id", "type": "bytes32"}
    ],
    "name": "depositErc20",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "depositor", "type": "address"},
      {"internalType": "address", "name": "token", "type": "address"},
      {"internalType": "uint256", "name": "amount", "type": "uint256"},
      {"internalType": "bytes32", "name": "id", "type": "bytes32"}
    ],
    "name": "depositErc20",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "depositor", "type": "address"},
      {"internalType": "bytes32", "name": "id", "type": "bytes32"}
    ],
    "name": "depositNative",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "eip712Domain",
    "outputs": [
      {"internalType": "bytes1", "name": "fields", "type": "bytes1"},
      {"internalType": "string", "name": "name", "type": "string"},
      {"internalType": "string", "name": "version", "type": "string"},
      {"internalType": "uint256", "name": "chainId", "type": "uint256"},
      {
        "internalType": "address",
        "name": "verifyingContract",
        "type": "address"
      },
      {"internalType": "bytes32", "name": "salt", "type": "bytes32"},
      {"internalType": "uint256[]", "name": "extensions", "type": "uint256[]"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "components": [
          {
            "components": [
              {"internalType": "address", "name": "to", "type": "address"},
              {"internalType": "bytes", "name": "data", "type": "bytes"},
              {"internalType": "uint256", "name": "value", "type": "uint256"},
              {"internalType": "bool", "name": "allowFailure", "type": "bool"}
            ],
            "internalType": "struct Call[]",
            "name": "calls",
            "type": "tuple[]"
          },
          {"internalType": "uint256", "name": "nonce", "type": "uint256"},
          {"internalType": "uint256", "name": "expiration", "type": "uint256"}
        ],
        "internalType": "struct CallRequest",
        "name": "request",
        "type": "tuple"
      },
      {"internalType": "bytes", "name": "signature", "type": "bytes"}
    ],
    "name": "execute",
    "outputs": [
      {
        "components": [
          {"internalType": "bool", "name": "success", "type": "bool"},
          {"internalType": "bytes", "name": "returnData", "type": "bytes"}
        ],
        "internalType": "struct CallResult[]",
        "name": "results",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      {"internalType": "address", "name": "result", "type": "address"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "pendingOwner", "type": "address"}
    ],
    "name": "ownershipHandoverExpiresAt",
    "outputs": [
      {"internalType": "uint256", "name": "result", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "renounceOwnership",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "requestOwnershipHandover",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "_allocator", "type": "address"}
    ],
    "name": "setAllocator",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "newOwner", "type": "address"}
    ],
    "name": "transferOwnership",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  }
];
