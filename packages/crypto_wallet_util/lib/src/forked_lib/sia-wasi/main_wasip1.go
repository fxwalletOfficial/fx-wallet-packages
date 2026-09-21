//go:build wasip1

package main

import (
	"encoding/json"
	"unsafe"
)

func main() {}

var wasmBuffers = make(map[uint32][]byte)

//go:wasmexport alloc
func alloc(size uint32) uint32 {
	if size == 0 {
		return 0
	}
	buf := make([]byte, size)
	ptr := uint32(uintptr(unsafe.Pointer(&buf[0])))
	wasmBuffers[ptr] = buf
	return ptr
}

//go:wasmexport release
func release(ptr uint32) {
	delete(wasmBuffers, ptr)
}

//go:wasmexport resultPtr
func resultPtr(result uint64) uint32 { return uint32(result >> 32) }

//go:wasmexport resultLen
func resultLen(result uint64) uint32 { return uint32(result) }

func readWasmBytes(ptr, length uint32) []byte {
	if length == 0 {
		return nil
	}
	return unsafe.Slice((*byte)(unsafe.Pointer(uintptr(ptr))), length)
}

func reportWasm(result []byte, err error) uint64 {
	if err != nil {
		result, _ = json.Marshal(map[string]string{"error": err.Error()})
	}
	ptr := alloc(uint32(len(result)))
	copy(readWasmBytes(ptr, uint32(len(result))), result)
	return uint64(ptr)<<32 | uint64(uint32(len(result)))
}

//go:wasmexport getUnsignedV2Transaction
func getUnsignedV2Transaction(ptr, length uint32) uint64 {
	result, err := unsignedV2TransactionJSON(string(readWasmBytes(ptr, length)))
	return reportWasm(result, err)
}

//go:wasmexport getV2TransactionSemantics
func getV2TransactionSemantics(ptr, length uint32) uint64 {
	result, err := extractV2TransactionSemanticsJSON(readWasmBytes(ptr, length))
	return reportWasm(result, err)
}

//go:wasmexport inspectV2TransactionSemantics
func inspectV2TransactionSemantics(ptr, length uint32) uint64 {
	result, err := inspectV2TransactionSemanticsJSON(readWasmBytes(ptr, length))
	return reportWasm(result, err)
}
