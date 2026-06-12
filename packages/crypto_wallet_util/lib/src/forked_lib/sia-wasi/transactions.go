package main

import (
	"encoding/json"
	"fmt"

	"go.sia.tech/core/consensus"
	"go.sia.tech/core/types"
)

func signingState() *consensus.State {
	network := new(consensus.Network)
	network.HardforkV2.AllowHeight = 500

	return &consensus.State{
		Index: types.ChainIndex{
			Height: 1000,
		},
		Network: network,
	}
}

func unsignedTransactionJSON(jsonTxn string, sigIndicesLen int) ([]byte, error) {
	var txn types.Transaction
	if err := json.Unmarshal([]byte(jsonTxn), &txn); err != nil {
		return nil, err
	}
	if sigIndicesLen < 0 || sigIndicesLen > len(txn.Signatures) {
		return nil, fmt.Errorf("signature index length %d out of range", sigIndicesLen)
	}

	cs := signingState()
	for i := 0; i < sigIndicesLen; i++ {
		sigHash := cs.WholeSigHash(txn, txn.Signatures[i].ParentID, 0, 0, nil)
		sig := sigHash
		txn.Signatures[i].Signature = sig[:]
	}

	return json.Marshal(txn)
}

func unsignedV2TransactionJSON(jsonTxn string) ([]byte, error) {
	var txn types.V2Transaction
	if err := json.Unmarshal([]byte(jsonTxn), &txn); err != nil {
		return nil, err
	}

	sigHash := signingState().InputSigHash(txn)
	var sig [64]byte
	copy(sig[:], sigHash[:])

	for i := range txn.SiacoinInputs {
		txn.SiacoinInputs[i].SatisfiedPolicy.Signatures = []types.Signature{sig}
	}

	return json.Marshal(txn)
}
