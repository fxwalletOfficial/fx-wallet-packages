package main

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"

	"go.sia.tech/core/types"
)

const (
	semanticProfile    = "sia-v2-siacoin-transfer-v1"
	maxTransferInputs  = 1000
	maxTransferOutputs = 1000
	// Keep successful extraction and inspection within the SC V2 UR wire cap.
	maxSemanticBytes = 32 * 1024
)

type semanticRequest struct {
	Transaction     json.RawMessage `json:"transaction"`
	ChangeAddresses []string        `json:"changeAddresses,omitempty"`
}

type semanticInspectRequest struct {
	Semantics       string   `json:"semantics"`
	ChangeAddresses []string `json:"changeAddresses,omitempty"`
}

type semanticOutput struct {
	Value    string `json:"value"`
	Address  string `json:"address"`
	IsChange bool   `json:"isChange"`
}

type semanticResponse struct {
	Profile      string           `json:"profile"`
	Semantics    string           `json:"semantics"`
	InputSigHash string           `json:"inputSigHash"`
	InputCount   int              `json:"inputCount"`
	ParentIDs    []string         `json:"parentIds"`
	Outputs      []semanticOutput `json:"outputs"`
	MinerFee     string           `json:"minerFee"`
	ByteLength   int              `json:"byteLength"`
}

func decodeStrictJSON(data []byte, dst any) error {
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.DisallowUnknownFields()
	if err := dec.Decode(dst); err != nil {
		return err
	}
	if err := dec.Decode(new(any)); !errors.Is(err, io.EOF) {
		if err == nil {
			return errors.New("unexpected trailing JSON value")
		}
		return fmt.Errorf("invalid trailing JSON: %w", err)
	}
	return nil
}

func validateTransferProfile(txn types.V2Transaction) error {
	if len(txn.SiacoinInputs) == 0 || len(txn.SiacoinInputs) > maxTransferInputs {
		return fmt.Errorf("siacoin input count must be in [1, %d], got %d", maxTransferInputs, len(txn.SiacoinInputs))
	}
	if len(txn.SiacoinOutputs) == 0 || len(txn.SiacoinOutputs) > maxTransferOutputs {
		return fmt.Errorf("siacoin output count must be in [1, %d], got %d", maxTransferOutputs, len(txn.SiacoinOutputs))
	}
	for i, output := range txn.SiacoinOutputs {
		if output.Value.IsZero() {
			return fmt.Errorf("siacoin output %d has zero value", i)
		}
	}
	if len(txn.SiafundInputs) != 0 {
		return errors.New("siafundInputs are unsupported by the transfer profile")
	}
	if len(txn.SiafundOutputs) != 0 {
		return errors.New("siafundOutputs are unsupported by the transfer profile")
	}
	if len(txn.FileContracts) != 0 {
		return errors.New("fileContracts are unsupported by the transfer profile")
	}
	if len(txn.FileContractRevisions) != 0 {
		return errors.New("fileContractRevisions are unsupported by the transfer profile")
	}
	if len(txn.FileContractResolutions) != 0 {
		return errors.New("fileContractResolutions are unsupported by the transfer profile")
	}
	if len(txn.Attestations) != 0 {
		return errors.New("attestations are unsupported by the transfer profile")
	}
	if len(txn.ArbitraryData) != 0 {
		return errors.New("arbitraryData is unsupported by the transfer profile")
	}
	if txn.NewFoundationAddress != nil {
		return errors.New("newFoundationAddress is unsupported by the transfer profile")
	}

	seen := make(map[types.SiacoinOutputID]struct{}, len(txn.SiacoinInputs))
	for i := range txn.SiacoinInputs {
		id := txn.SiacoinInputs[i].Parent.ID
		if id == (types.SiacoinOutputID{}) {
			return fmt.Errorf("siacoin input %d has a zero parent ID", i)
		}
		if _, exists := seen[id]; exists {
			return fmt.Errorf("siacoin input %d duplicates parent ID %s", i, id)
		}
		seen[id] = struct{}{}
	}
	return nil
}

func isMissingJSONField(field json.RawMessage) bool {
	return len(field) == 0 || bytes.Equal(bytes.TrimSpace(field), []byte("null"))
}

func validateRequiredSemanticFields(input []byte) error {
	var fields struct {
		SiacoinOutputs []struct {
			Value   json.RawMessage `json:"value"`
			Address json.RawMessage `json:"address"`
		} `json:"siacoinOutputs"`
		MinerFee json.RawMessage `json:"minerFee"`
	}
	if err := json.Unmarshal(input, &fields); err != nil {
		return err
	}
	for i, output := range fields.SiacoinOutputs {
		if isMissingJSONField(output.Value) {
			return fmt.Errorf("siacoin output %d value is required", i)
		}
		if isMissingJSONField(output.Address) {
			return fmt.Errorf("siacoin output %d address is required", i)
		}
	}
	if isMissingJSONField(fields.MinerFee) {
		return errors.New("minerFee is required")
	}
	return nil
}

func encodeV2TransactionSemantics(txn types.V2Transaction) ([]byte, error) {
	var buf bytes.Buffer
	enc := types.NewEncoder(&buf)
	types.V2TransactionSemantics(txn).EncodeTo(enc)
	if err := enc.Flush(); err != nil {
		return nil, fmt.Errorf("encode transaction semantics: %w", err)
	}
	return buf.Bytes(), nil
}

func transactionFromSemantics(semantic []byte) (types.V2Transaction, error) {
	if len(semantic) > maxSemanticBytes {
		return types.V2Transaction{}, fmt.Errorf("semantic payload exceeds %d bytes", maxSemanticBytes)
	}
	r := bytes.NewReader(semantic)
	d := types.NewDecoder(io.LimitedReader{R: r, N: int64(len(semantic))})

	inputCount := d.ReadUint64()
	if inputCount == 0 || inputCount > maxTransferInputs {
		return types.V2Transaction{}, fmt.Errorf("siacoin input count must be in [1, %d], got %d", maxTransferInputs, inputCount)
	}
	txn := types.V2Transaction{SiacoinInputs: make([]types.V2SiacoinInput, int(inputCount))}
	for i := range txn.SiacoinInputs {
		txn.SiacoinInputs[i].Parent.ID.DecodeFrom(d)
	}

	outputCount := d.ReadUint64()
	if outputCount == 0 || outputCount > maxTransferOutputs {
		return types.V2Transaction{}, fmt.Errorf("siacoin output count must be in [1, %d], got %d", maxTransferOutputs, outputCount)
	}
	txn.SiacoinOutputs = make([]types.SiacoinOutput, int(outputCount))
	for i := range txn.SiacoinOutputs {
		(*types.V2SiacoinOutput)(&txn.SiacoinOutputs[i]).DecodeFrom(d)
	}

	unsupported := []string{
		"siafundInputs",
		"siafundOutputs",
		"fileContracts",
		"fileContractRevisions",
		"fileContractResolutions",
		"attestations",
	}
	for _, field := range unsupported {
		if count := d.ReadUint64(); count != 0 {
			return types.V2Transaction{}, fmt.Errorf("%s are unsupported by the transfer profile", field)
		}
	}
	if arbitraryData := d.ReadBytes(); len(arbitraryData) != 0 {
		return types.V2Transaction{}, errors.New("arbitraryData is unsupported by the transfer profile")
	}
	if d.ReadBool() {
		return types.V2Transaction{}, errors.New("newFoundationAddress is unsupported by the transfer profile")
	}
	(*types.V2Currency)(&txn.MinerFee).DecodeFrom(d)
	if err := d.Err(); err != nil {
		return types.V2Transaction{}, fmt.Errorf("decode transaction semantics: %w", err)
	}
	if r.Len() != 0 {
		return types.V2Transaction{}, fmt.Errorf("semantic payload has %d trailing bytes", r.Len())
	}
	if err := validateTransferProfile(txn); err != nil {
		return types.V2Transaction{}, err
	}
	canonical, err := encodeV2TransactionSemantics(txn)
	if err != nil {
		return types.V2Transaction{}, err
	}
	if !bytes.Equal(canonical, semantic) {
		return types.V2Transaction{}, errors.New("semantic payload is not canonical")
	}
	return txn, nil
}

func parseChangeAddresses(addresses []string) (map[types.Address]struct{}, error) {
	change := make(map[types.Address]struct{}, len(addresses))
	for i, encoded := range addresses {
		address, err := types.ParseAddress(encoded)
		if err != nil {
			return nil, fmt.Errorf("invalid change address %d: %w", i, err)
		}
		if address.String() != encoded {
			return nil, fmt.Errorf("change address %d is not canonical", i)
		}
		change[address] = struct{}{}
	}
	return change, nil
}

func responseForSemantics(semantic []byte, changeAddresses []string) (semanticResponse, error) {
	txn, err := transactionFromSemantics(semantic)
	if err != nil {
		return semanticResponse{}, err
	}
	change, err := parseChangeAddresses(changeAddresses)
	if err != nil {
		return semanticResponse{}, err
	}

	response := semanticResponse{
		Profile:      semanticProfile,
		Semantics:    hex.EncodeToString(semantic),
		InputSigHash: signingState().InputSigHash(txn).String(),
		InputCount:   len(txn.SiacoinInputs),
		ParentIDs:    make([]string, len(txn.SiacoinInputs)),
		Outputs:      make([]semanticOutput, len(txn.SiacoinOutputs)),
		MinerFee:     txn.MinerFee.ExactString(),
		ByteLength:   len(semantic),
	}
	for i := range txn.SiacoinInputs {
		response.ParentIDs[i] = txn.SiacoinInputs[i].Parent.ID.String()
	}
	for i, output := range txn.SiacoinOutputs {
		_, isChange := change[output.Address]
		response.Outputs[i] = semanticOutput{
			Value:    output.Value.ExactString(),
			Address:  output.Address.String(),
			IsChange: isChange,
		}
	}
	return response, nil
}

func extractV2TransactionSemanticsJSON(input []byte) ([]byte, error) {
	var request semanticRequest
	if err := decodeStrictJSON(input, &request); err != nil {
		return nil, fmt.Errorf("decode semantic request: %w", err)
	}
	if len(request.Transaction) == 0 {
		return nil, errors.New("transaction is required")
	}

	var txn types.V2Transaction
	if err := decodeStrictJSON(request.Transaction, &txn); err != nil {
		return nil, fmt.Errorf("decode v2 transaction: %w", err)
	}
	if err := validateRequiredSemanticFields(request.Transaction); err != nil {
		return nil, fmt.Errorf("validate v2 transaction fields: %w", err)
	}
	if err := validateTransferProfile(txn); err != nil {
		return nil, err
	}
	semantic, err := encodeV2TransactionSemantics(txn)
	if err != nil {
		return nil, err
	}
	response, err := responseForSemantics(semantic, request.ChangeAddresses)
	if err != nil {
		return nil, err
	}
	return json.Marshal(response)
}

func inspectV2TransactionSemanticsJSON(input []byte) ([]byte, error) {
	var request semanticInspectRequest
	if err := decodeStrictJSON(input, &request); err != nil {
		return nil, fmt.Errorf("decode semantic inspection request: %w", err)
	}
	semantic, err := hex.DecodeString(request.Semantics)
	if err != nil {
		return nil, fmt.Errorf("decode semantic hex: %w", err)
	}
	if hex.EncodeToString(semantic) != request.Semantics {
		return nil, errors.New("semantic hex is not canonical lowercase encoding")
	}
	response, err := responseForSemantics(semantic, request.ChangeAddresses)
	if err != nil {
		return nil, err
	}
	return json.Marshal(response)
}
