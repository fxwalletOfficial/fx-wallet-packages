//go:build !wasip1 && cgo

package main

/*
#include <stdlib.h>
*/
import "C"
import (
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

//export free_string
func free_string(str *C.char) {
	C.free(unsafe.Pointer(str))
}
