const cowswapAbi = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "_cowSwapSettlement",
        "type": "address",
        "internalType": "contract ICoWSwapSettlement"
      },
      {
        "name": "_wrappedNativeToken",
        "type": "address",
        "internalType": "contract IWrappedNativeToken"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "name": "EthTransferFailed",
    "type": "error",
    "inputs": []
  },
  {
    "name": "IncorrectEthAmount",
    "type": "error",
    "inputs": []
  },
  {
    "name": "NotAllowedToInvalidateOrder",
    "type": "error",
    "inputs": [
      {
        "name": "orderHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ]
  },
  {
    "name": "NotAllowedZeroSellAmount",
    "type": "error",
    "inputs": []
  },
  {
    "name": "OrderIsAlreadyExpired",
    "type": "error",
    "inputs": []
  },
  {
    "name": "OrderIsAlreadyOwned",
    "type": "error",
    "inputs": [
      {
        "name": "orderHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ]
  },
  {
    "name": "ReceiverMustBeSet",
    "type": "error",
    "inputs": []
  },
  {
    "name": "OrderInvalidation",
    "type": "event",
    "inputs": [
      {
        "name": "orderUid",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      }
    ],
    "anonymous": false
  },
  {
    "name": "OrderPlacement",
    "type": "event",
    "inputs": [
      {
        "name": "sender",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "order",
        "type": "tuple",
        "indexed": false,
        "components": [
          {
            "name": "sellToken",
            "type": "address",
            "internalType": "contract IERC20"
          },
          {
            "name": "buyToken",
            "type": "address",
            "internalType": "contract IERC20"
          },
          {
            "name": "receiver",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "sellAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "buyAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "validTo",
            "type": "uint32",
            "internalType": "uint32"
          },
          {
            "name": "appData",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "feeAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "kind",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "partiallyFillable",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "sellTokenBalance",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "buyTokenBalance",
            "type": "bytes32",
            "internalType": "bytes32"
          }
        ],
        "internalType": "struct GPv2Order.Data"
      },
      {
        "name": "signature",
        "type": "tuple",
        "indexed": false,
        "components": [
          {
            "name": "scheme",
            "type": "uint8",
            "internalType": "enum ICoWSwapOnchainOrders.OnchainSigningScheme"
          },
          {
            "name": "data",
            "type": "bytes",
            "internalType": "bytes"
          }
        ],
        "internalType": "struct ICoWSwapOnchainOrders.OnchainSignature"
      },
      {
        "name": "data",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      }
    ],
    "anonymous": false
  },
  {
    "name": "OrderRefund",
    "type": "event",
    "inputs": [
      {
        "name": "orderUid",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      },
      {
        "name": "refunder",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "name": "cowSwapSettlement",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract ICoWSwapSettlement"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "createOrder",
    "type": "function",
    "inputs": [
      {
        "name": "order",
        "type": "tuple",
        "components": [
          {
            "name": "buyToken",
            "type": "address",
            "internalType": "contract IERC20"
          },
          {
            "name": "receiver",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "sellAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "buyAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "appData",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "feeAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "validTo",
            "type": "uint32",
            "internalType": "uint32"
          },
          {
            "name": "partiallyFillable",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "quoteId",
            "type": "int64",
            "internalType": "int64"
          }
        ],
        "internalType": "struct EthFlowOrder.Data"
      }
    ],
    "outputs": [
      {
        "name": "orderHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "name": "invalidateOrder",
    "type": "function",
    "inputs": [
      {
        "name": "order",
        "type": "tuple",
        "components": [
          {
            "name": "buyToken",
            "type": "address",
            "internalType": "contract IERC20"
          },
          {
            "name": "receiver",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "sellAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "buyAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "appData",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "feeAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "validTo",
            "type": "uint32",
            "internalType": "uint32"
          },
          {
            "name": "partiallyFillable",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "quoteId",
            "type": "int64",
            "internalType": "int64"
          }
        ],
        "internalType": "struct EthFlowOrder.Data"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "invalidateOrdersIgnoringNotAllowed",
    "type": "function",
    "inputs": [
      {
        "name": "orderArray",
        "type": "tuple[]",
        "components": [
          {
            "name": "buyToken",
            "type": "address",
            "internalType": "contract IERC20"
          },
          {
            "name": "receiver",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "sellAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "buyAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "appData",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "feeAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "validTo",
            "type": "uint32",
            "internalType": "uint32"
          },
          {
            "name": "partiallyFillable",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "quoteId",
            "type": "int64",
            "internalType": "int64"
          }
        ],
        "internalType": "struct EthFlowOrder.Data[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "isValidSignature",
    "type": "function",
    "inputs": [
      {
        "name": "orderHash",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "orders",
    "type": "function",
    "inputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "validTo",
        "type": "uint32",
        "internalType": "uint32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "unwrap",
    "type": "function",
    "inputs": [
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "wrap",
    "type": "function",
    "inputs": [
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "wrapAll",
    "type": "function",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "wrappedNativeToken",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract IWrappedNativeToken"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "receive",
    "stateMutability": "payable"
  }
];
