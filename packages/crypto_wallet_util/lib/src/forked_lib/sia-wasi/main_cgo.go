//go:build !wasip1 && cgo

package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"encoding/json"
	"unsafe"
)

func main() {}

//export process_sc_transaction
func process_sc_transaction(inputJson *C.char, outputJson **C.char) C.int {
	input := C.GoString(inputJson)

	result, err := unsignedV2TransactionJSON(input)
	if err != nil {
		*outputJson = C.CString(`{"error":"` + err.Error() + `"}`)
		return -1
	}

	*outputJson = C.CString(string(result))
	return 0
}

func writeResult(outputJson **C.char, result []byte, err error) C.int {
	if err != nil {
		result, _ = json.Marshal(map[string]string{"error": err.Error()})
		*outputJson = C.CString(string(result))
		return -1
	}
	*outputJson = C.CString(string(result))
	return 0
}

//export extract_sc_v2_transaction_semantics
func extract_sc_v2_transaction_semantics(inputJson *C.char, outputJson **C.char) C.int {
	result, err := extractV2TransactionSemanticsJSON([]byte(C.GoString(inputJson)))
	return writeResult(outputJson, result, err)
}

//export inspect_sc_v2_transaction_semantics
func inspect_sc_v2_transaction_semantics(inputJson *C.char, outputJson **C.char) C.int {
	result, err := inspectV2TransactionSemanticsJSON([]byte(C.GoString(inputJson)))
	return writeResult(outputJson, result, err)
}

//export free_string
func free_string(str *C.char) {
	C.free(unsafe.Pointer(str))
}
