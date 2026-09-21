package main

import (
	"bytes"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math/big"
	"os"
	"strings"
	"testing"
	"time"

	"go.sia.tech/core/types"
)

const officialDigest = "c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d"

func fixtureJSON(t *testing.T) []byte {
	t.Helper()
	b, err := os.ReadFile("../../../../test/transaction/data/sc_unsigned.json")
	if err != nil {
		t.Fatal(err)
	}
	return b
}

func fixtureMap(t *testing.T) map[string]any {
	t.Helper()
	var value map[string]any
	if err := json.Unmarshal(fixtureJSON(t), &value); err != nil {
		t.Fatal(err)
	}
	return value
}

func cloneMap(t *testing.T, value map[string]any) map[string]any {
	t.Helper()
	b, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	var clone map[string]any
	if err := json.Unmarshal(b, &clone); err != nil {
		t.Fatal(err)
	}
	return clone
}

func extractResponse(t *testing.T, transaction map[string]any) semanticResponse {
	t.Helper()
	request, err := json.Marshal(semanticRequest{Transaction: mustJSON(t, transaction)})
	if err != nil {
		t.Fatal(err)
	}
	responseJSON, err := extractV2TransactionSemanticsJSON(request)
	if err != nil {
		t.Fatal(err)
	}
	var response semanticResponse
	if err := json.Unmarshal(responseJSON, &response); err != nil {
		t.Fatal(err)
	}
	return response
}

func mustJSON(t *testing.T, value any) json.RawMessage {
	t.Helper()
	b, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

func fullTransactionInputSigHashJSON(input []byte) (types.Hash256, error) {
	var txn types.V2Transaction
	if err := decodeStrictJSON(input, &txn); err != nil {
		return types.Hash256{}, err
	}
	if err := validateTransferProfile(txn); err != nil {
		return types.Hash256{}, err
	}
	return signingState().InputSigHash(txn), nil
}

func TestOfficialVectorFullAndSemanticDigestsMatch(t *testing.T) {
	fullJSON := fixtureJSON(t)
	fullDigest, err := fullTransactionInputSigHashJSON(fullJSON)
	if err != nil {
		t.Fatal(err)
	}
	response := extractResponse(t, fixtureMap(t))
	if fullDigest.String() != officialDigest {
		t.Fatalf("full payload digest: got %s, want %s", fullDigest, officialDigest)
	}
	if response.InputSigHash != officialDigest {
		t.Fatalf("semantic digest: got %s, want %s", response.InputSigHash, officialDigest)
	}
	semantic, err := hex.DecodeString(response.Semantics)
	if err != nil {
		t.Fatal(err)
	}
	if response.ByteLength != len(semantic) || len(semantic) != 217 {
		t.Fatalf("semantic byte length: response=%d actual=%d want=217", response.ByteLength, len(semantic))
	}
	parsed, err := transactionFromSemantics(semantic)
	if err != nil {
		t.Fatal(err)
	}
	if got := signingState().InputSigHash(parsed).String(); got != fullDigest.String() {
		t.Fatalf("parsed semantic digest: got %s, want %s", got, fullDigest)
	}
}

func TestSemanticDigestMutations(t *testing.T) {
	base := fixtureMap(t)
	baseResponse := extractResponse(t, base)

	semanticMutations := map[string]func(map[string]any){
		"parent ID": func(tx map[string]any) {
			parent := tx["siacoinInputs"].([]any)[0].(map[string]any)["parent"].(map[string]any)
			parent["id"] = "d1" + parent["id"].(string)[2:]
		},
		"output address": func(tx map[string]any) {
			outputs := tx["siacoinOutputs"].([]any)
			outputs[0].(map[string]any)["address"] = outputs[1].(map[string]any)["address"]
		},
		"output value": func(tx map[string]any) {
			output := tx["siacoinOutputs"].([]any)[0].(map[string]any)
			value, _ := new(big.Int).SetString(output["value"].(string), 10)
			output["value"] = value.Add(value, big.NewInt(1)).String()
		},
		"miner fee": func(tx map[string]any) {
			value, _ := new(big.Int).SetString(tx["minerFee"].(string), 10)
			tx["minerFee"] = value.Add(value, big.NewInt(1)).String()
		},
	}
	for name, mutate := range semanticMutations {
		t.Run(name, func(t *testing.T) {
			mutated := cloneMap(t, base)
			mutate(mutated)
			if got := extractResponse(t, mutated).InputSigHash; got == baseResponse.InputSigHash {
				t.Fatalf("digest did not change: %s", got)
			}
		})
	}

	witnessMutations := map[string]func(map[string]any){
		"leaf index": func(tx map[string]any) {
			state := tx["siacoinInputs"].([]any)[0].(map[string]any)["parent"].(map[string]any)["stateElement"].(map[string]any)
			state["leafIndex"] = state["leafIndex"].(float64) + 1
		},
		"merkle proof": func(tx map[string]any) {
			state := tx["siacoinInputs"].([]any)[0].(map[string]any)["parent"].(map[string]any)["stateElement"].(map[string]any)
			proof := state["merkleProof"].([]any)
			proof[0] = "ed" + proof[0].(string)[2:]
		},
		"parent output": func(tx map[string]any) {
			parent := tx["siacoinInputs"].([]any)[0].(map[string]any)["parent"].(map[string]any)
			parent["siacoinOutput"].(map[string]any)["value"] = "1"
		},
		"satisfied policy": func(tx map[string]any) {
			input := tx["siacoinInputs"].([]any)[0].(map[string]any)
			policy := input["satisfiedPolicy"].(map[string]any)["policy"].(map[string]any)["policy"].(map[string]any)
			key := policy["publicKeys"].([]any)[0].(string)
			policy["publicKeys"].([]any)[0] = key[:len(key)-1] + "c"
		},
	}
	for name, mutate := range witnessMutations {
		t.Run(name, func(t *testing.T) {
			mutated := cloneMap(t, base)
			mutate(mutated)
			response := extractResponse(t, mutated)
			if response.InputSigHash != baseResponse.InputSigHash || response.Semantics != baseResponse.Semantics {
				t.Fatalf("witness mutation changed semantic signing data")
			}
		})
	}
}

func TestSemanticParserFailsClosed(t *testing.T) {
	response := extractResponse(t, fixtureMap(t))
	semantic, err := hex.DecodeString(response.Semantics)
	if err != nil {
		t.Fatal(err)
	}

	tests := map[string][]byte{
		"empty":                     nil,
		"truncated":                 semantic[:len(semantic)-1],
		"trailing":                  append(append([]byte(nil), semantic...), 0),
		"invalid optional bool":     append([]byte(nil), semantic...),
		"unsupported siafund input": append([]byte(nil), semantic...),
		"too many inputs":           append([]byte(nil), semantic...),
	}
	tests["invalid optional bool"][len(semantic)-17] = 2
	// After the input IDs and siacoin outputs comes the siafund input count.
	tests["unsupported siafund input"][8+32+8+2*48] = 1
	binary.LittleEndian.PutUint64(tests["too many inputs"][:8], maxTransferInputs+1)

	for name, payload := range tests {
		t.Run(name, func(t *testing.T) {
			if _, err := transactionFromSemantics(payload); err == nil {
				t.Fatal("expected strict semantic parser failure")
			}
		})
	}

	uppercaseRequest, err := json.Marshal(semanticInspectRequest{
		Semantics: strings.ToUpper(response.Semantics),
	})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := inspectV2TransactionSemanticsJSON(uppercaseRequest); err == nil {
		t.Fatal("expected non-canonical semantic hex rejection")
	}
}

func TestUnsupportedAndUnknownFullPayloadFieldsFailClosed(t *testing.T) {
	base := fixtureMap(t)
	tests := map[string]func(map[string]any){
		"unsupported known field": func(tx map[string]any) {
			tx["attestations"] = []any{map[string]any{}}
		},
		"unknown field": func(tx map[string]any) {
			tx["futureConsensusField"] = true
		},
		"unknown nested field": func(tx map[string]any) {
			parent := tx["siacoinInputs"].([]any)[0].(map[string]any)["parent"].(map[string]any)
			parent["futureWitnessField"] = true
		},
		"too many inputs": func(tx map[string]any) {
			input := tx["siacoinInputs"].([]any)[0]
			inputs := make([]any, maxTransferInputs+1)
			for i := range inputs {
				inputs[i] = input
			}
			tx["siacoinInputs"] = inputs
		},
	}
	for name, mutate := range tests {
		t.Run(name, func(t *testing.T) {
			tx := cloneMap(t, base)
			mutate(tx)
			request, err := json.Marshal(semanticRequest{Transaction: mustJSON(t, tx)})
			if err != nil {
				t.Fatal(err)
			}
			if _, err := extractV2TransactionSemanticsJSON(request); err == nil {
				t.Fatal("expected full payload rejection")
			}
		})
	}
}

func TestRequiredSemanticFieldsFailClosed(t *testing.T) {
	base := fixtureMap(t)
	tests := map[string]func(map[string]any){
		"missing output value": func(tx map[string]any) {
			delete(tx["siacoinOutputs"].([]any)[0].(map[string]any), "value")
		},
		"null output value": func(tx map[string]any) {
			tx["siacoinOutputs"].([]any)[0].(map[string]any)["value"] = nil
		},
		"missing output address": func(tx map[string]any) {
			delete(tx["siacoinOutputs"].([]any)[0].(map[string]any), "address")
		},
		"null output address": func(tx map[string]any) {
			tx["siacoinOutputs"].([]any)[0].(map[string]any)["address"] = nil
		},
		"missing miner fee": func(tx map[string]any) {
			delete(tx, "minerFee")
		},
		"null miner fee": func(tx map[string]any) {
			tx["minerFee"] = nil
		},
	}
	for name, mutate := range tests {
		t.Run(name, func(t *testing.T) {
			tx := cloneMap(t, base)
			mutate(tx)
			request, err := json.Marshal(semanticRequest{Transaction: mustJSON(t, tx)})
			if err != nil {
				t.Fatal(err)
			}
			if _, err := extractV2TransactionSemanticsJSON(request); err == nil {
				t.Fatal("expected missing or null semantic field rejection")
			}
		})
	}
}

func TestZeroValueOutputFailsClosed(t *testing.T) {
	tx := fixtureMap(t)
	tx["siacoinOutputs"].([]any)[0].(map[string]any)["value"] = "0"
	request, err := json.Marshal(semanticRequest{Transaction: mustJSON(t, tx)})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := extractV2TransactionSemanticsJSON(request); err == nil {
		t.Fatal("expected full payload with zero-value output to be rejected")
	}

	var typed types.V2Transaction
	if err := json.Unmarshal(fixtureJSON(t), &typed); err != nil {
		t.Fatal(err)
	}
	typed.SiacoinOutputs[0].Value = types.ZeroCurrency
	semantic, err := encodeV2TransactionSemantics(typed)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := transactionFromSemantics(semantic); err == nil {
		t.Fatal("expected semantic payload with zero-value output to be rejected")
	}
}

func TestTransferProfileCountAndParentBoundaries(t *testing.T) {
	var base types.V2Transaction
	if err := json.Unmarshal(fixtureJSON(t), &base); err != nil {
		t.Fatal(err)
	}

	t.Run("zero inputs", func(t *testing.T) {
		txn := base
		txn.SiacoinInputs = nil
		if err := validateTransferProfile(txn); err == nil {
			t.Fatal("expected zero inputs to be rejected")
		}
	})
	t.Run("zero outputs", func(t *testing.T) {
		txn := base
		txn.SiacoinOutputs = nil
		if err := validateTransferProfile(txn); err == nil {
			t.Fatal("expected zero outputs to be rejected")
		}
	})
	t.Run("maximum outputs", func(t *testing.T) {
		txn := base
		txn.SiacoinOutputs = make([]types.SiacoinOutput, maxTransferOutputs)
		for i := range txn.SiacoinOutputs {
			txn.SiacoinOutputs[i] = base.SiacoinOutputs[0]
		}
		if err := validateTransferProfile(txn); err != nil {
			t.Fatal(err)
		}
	})
	t.Run("too many outputs", func(t *testing.T) {
		txn := base
		txn.SiacoinOutputs = make([]types.SiacoinOutput, maxTransferOutputs+1)
		for i := range txn.SiacoinOutputs {
			txn.SiacoinOutputs[i] = base.SiacoinOutputs[0]
		}
		if err := validateTransferProfile(txn); err == nil {
			t.Fatal("expected output count above the profile limit to be rejected")
		}
	})
	t.Run("zero parent ID", func(t *testing.T) {
		txn := base
		txn.SiacoinInputs[0].Parent.ID = types.SiacoinOutputID{}
		if err := validateTransferProfile(txn); err == nil {
			t.Fatal("expected zero parent ID to be rejected")
		}
	})
	t.Run("duplicate parent ID", func(t *testing.T) {
		txn := base
		txn.SiacoinInputs = append(txn.SiacoinInputs, txn.SiacoinInputs[0])
		if err := validateTransferProfile(txn); err == nil {
			t.Fatal("expected duplicate parent ID to be rejected")
		}
	})
}

func TestTransferProfileRejectsEveryUnsupportedField(t *testing.T) {
	var base types.V2Transaction
	if err := json.Unmarshal(fixtureJSON(t), &base); err != nil {
		t.Fatal(err)
	}
	tests := map[string]func(*types.V2Transaction){
		"siafund inputs": func(txn *types.V2Transaction) {
			txn.SiafundInputs = []types.V2SiafundInput{{}}
		},
		"siafund outputs": func(txn *types.V2Transaction) {
			txn.SiafundOutputs = []types.SiafundOutput{{}}
		},
		"file contracts": func(txn *types.V2Transaction) {
			txn.FileContracts = []types.V2FileContract{{}}
		},
		"file contract revisions": func(txn *types.V2Transaction) {
			txn.FileContractRevisions = []types.V2FileContractRevision{{}}
		},
		"file contract resolutions": func(txn *types.V2Transaction) {
			txn.FileContractResolutions = []types.V2FileContractResolution{{}}
		},
		"attestations": func(txn *types.V2Transaction) {
			txn.Attestations = []types.Attestation{{}}
		},
		"arbitrary data": func(txn *types.V2Transaction) {
			txn.ArbitraryData = []byte{1}
		},
		"foundation address": func(txn *types.V2Transaction) {
			address := types.VoidAddress
			txn.NewFoundationAddress = &address
		},
	}
	for name, mutate := range tests {
		t.Run(name, func(t *testing.T) {
			txn := base
			mutate(&txn)
			if err := validateTransferProfile(txn); err == nil {
				t.Fatal("expected unsupported field to be rejected")
			}
		})
	}
}

func TestChangeAddressValidation(t *testing.T) {
	var base types.V2Transaction
	if err := json.Unmarshal(fixtureJSON(t), &base); err != nil {
		t.Fatal(err)
	}
	address := base.SiacoinOutputs[0].Address.String()
	if change, err := parseChangeAddresses([]string{address, address}); err != nil {
		t.Fatal(err)
	} else if len(change) != 1 {
		t.Fatalf("duplicate change addresses should collapse to one entry, got %d", len(change))
	}
	for _, invalid := range []string{"not-an-address", strings.ToUpper(address)} {
		if _, err := parseChangeAddresses([]string{invalid}); err == nil {
			t.Fatalf("expected invalid change address %q to be rejected", invalid)
		}
	}
}

func TestSemanticScale(t *testing.T) {
	var base types.V2Transaction
	if err := json.Unmarshal(fixtureJSON(t), &base); err != nil {
		t.Fatal(err)
	}
	for _, count := range []int{1, 167, 1000} {
		t.Run(fmt.Sprint(count), func(t *testing.T) {
			txn := base
			txn.SiacoinInputs = make([]types.V2SiacoinInput, count)
			for i := range txn.SiacoinInputs {
				txn.SiacoinInputs[i] = base.SiacoinInputs[0]
				binary.LittleEndian.PutUint64(txn.SiacoinInputs[i].Parent.ID[:8], uint64(i+1))
			}
			semantic, err := encodeV2TransactionSemantics(txn)
			if err != nil {
				t.Fatal(err)
			}
			parsed, err := transactionFromSemantics(semantic)
			if err != nil {
				t.Fatal(err)
			}
			_ = signingState().InputSigHash(parsed)
			wantBytes := 89 + 32*count + 48*len(txn.SiacoinOutputs)
			if len(semantic) != wantBytes {
				t.Fatalf("semantic bytes: got %d, want %d", len(semantic), wantBytes)
			}

			const iterations = 100
			start := time.Now()
			for range iterations {
				encoded, err := encodeV2TransactionSemantics(txn)
				if err != nil {
					t.Fatal(err)
				}
				parsed, err := transactionFromSemantics(encoded)
				if err != nil {
					t.Fatal(err)
				}
				_ = signingState().InputSigHash(parsed)
			}
			average := time.Since(start) / iterations
			t.Logf("inputs=%d semanticBytes=%d averageEncodeParseHash=%s iterations=%d", count, len(semantic), average, iterations)
		})
	}
}

func TestMaximumSemanticSizeBoundary(t *testing.T) {
	var txn types.V2Transaction
	if err := json.Unmarshal(fixtureJSON(t), &txn); err != nil {
		t.Fatal(err)
	}
	baseInput := txn.SiacoinInputs[0]
	baseOutput := txn.SiacoinOutputs[0]
	txn.SiacoinInputs = make([]types.V2SiacoinInput, maxTransferInputs)
	for i := range txn.SiacoinInputs {
		txn.SiacoinInputs[i] = baseInput
		binary.LittleEndian.PutUint64(txn.SiacoinInputs[i].Parent.ID[:8], uint64(i+1))
	}
	txn.SiacoinOutputs = make([]types.SiacoinOutput, maxTransferOutputs)
	for i := range txn.SiacoinOutputs {
		txn.SiacoinOutputs[i] = baseOutput
	}

	semantic, err := encodeV2TransactionSemantics(txn)
	if err != nil {
		t.Fatal(err)
	}
	if len(semantic) != maxSemanticBytes {
		t.Fatalf("maximum semantic bytes: got %d, want %d", len(semantic), maxSemanticBytes)
	}
	if _, err := transactionFromSemantics(semantic); err != nil {
		t.Fatal(err)
	}
	if _, err := transactionFromSemantics(append(semantic, 0)); err == nil {
		t.Fatal("expected payload above maximum semantic size to be rejected")
	}
}

func TestChangeClassification(t *testing.T) {
	tx := fixtureMap(t)
	changeAddress := tx["siacoinOutputs"].([]any)[1].(map[string]any)["address"].(string)
	request, err := json.Marshal(semanticRequest{
		Transaction:     mustJSON(t, tx),
		ChangeAddresses: []string{changeAddress},
	})
	if err != nil {
		t.Fatal(err)
	}
	responseJSON, err := extractV2TransactionSemanticsJSON(request)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Contains(responseJSON, []byte(`"isChange":true`)) {
		t.Fatalf("change output was not classified: %s", responseJSON)
	}
}
