package main

import (
	"encoding/json"

	"go.sia.tech/core/consensus"
	"go.sia.tech/core/types"
)

// signingState returns a minimal consensus state sufficient for computing the
// V2 input signature hash. Only the V2 hardfork being active and a post-fork
// height matter for InputSigHash; the exact values (AllowHeight 500, Height
// 1000) are arbitrary as long as Height >= AllowHeight, and are pinned to match
// the reference sc.wasm output (golden-tested in sc_test/scp_test).
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
