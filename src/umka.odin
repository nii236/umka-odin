package umka

import "core:c"
import "core:fmt"


// Platform-specific library imports
when ODIN_OS == .Windows {foreign import umkalib "../lib/windows/umkalib.lib"}
when ODIN_OS == .Linux {foreign import umkalib "../lib/linux/libumka.a"}
when ODIN_OS == .Darwin && ODIN_ARCH == .amd64 {foreign import umkalib "../lib/macos/libumka.a"}
when ODIN_OS ==
	.Darwin && ODIN_ARCH == .arm64 {foreign import umkalib "../lib/macos-arm64/libumka.a"}

// Stack slot union equivalent
UmkaStackSlot :: struct {
	data: [8]u8, // Union data - 8 bytes to hold the largest member
}

// Generic helper procedures to access union members
umka_stack_slot_set :: proc(slot: ^UmkaStackSlot, val: $T) {
	(cast(^T)&slot.data[0])^ = val
}

umka_stack_slot_get :: proc(slot: ^UmkaStackSlot, $T: typeid) -> T {
	return (cast(^T)&slot.data[0])^
}

// // Convenience wrappers that maintain API compatibility
// umka_stack_slot_set_int :: proc(slot: ^UmkaStackSlot, val: i64) {
// 	umka_stack_slot_set(slot, val)
// }

// umka_stack_slot_get_int :: proc(slot: ^UmkaStackSlot) -> i64 {
// 	return umka_stack_slot_get(slot, i64)
// }

// umka_stack_slot_set_uint :: proc(slot: ^UmkaStackSlot, val: u64) {
// 	umka_stack_slot_set(slot, val)
// }

// umka_stack_slot_get_uint :: proc(slot: ^UmkaStackSlot) -> u64 {
// 	return umka_stack_slot_get(slot, u64)
// }

// umka_stack_slot_set_ptr :: proc(slot: ^UmkaStackSlot, val: rawptr) {
// 	umka_stack_slot_set(slot, val)
// }

// umka_stack_slot_get_ptr :: proc(slot: ^UmkaStackSlot) -> rawptr {
// 	return umka_stack_slot_get(slot, rawptr)
// }

// umka_stack_slot_set_real :: proc(slot: ^UmkaStackSlot, val: f64) {
// 	umka_stack_slot_set(slot, val)
// }

// umka_stack_slot_get_real :: proc(slot: ^UmkaStackSlot) -> f64 {
// 	return umka_stack_slot_get(slot, f64)
// }

// umka_stack_slot_set_real32 :: proc(slot: ^UmkaStackSlot, val: f32) {
// 	umka_stack_slot_set(slot, val)
// }

// umka_stack_slot_get_real32 :: proc(slot: ^UmkaStackSlot) -> f32 {
// 	return umka_stack_slot_get(slot, f32)
// }

// Function context structure
UmkaFuncContext :: struct {
	entryOffset: i64,
	params:      ^UmkaStackSlot,
	result:      ^UmkaStackSlot,
}

// External function callback type
UmkaExternFunc :: proc "c" (params: ^UmkaStackSlot, result: ^UmkaStackSlot)

// Hook event enum
UmkaHookEvent :: enum c.int {
	UMKA_HOOK_CALL   = 0,
	UMKA_HOOK_RETURN = 1,
}

// Hook function callback type
UmkaHookFunc :: proc "c" (fileName: cstring, funcName: cstring, line: c.int)

// Dynamic array structure (generic equivalent)
UmkaDynArray :: struct {
	internal: rawptr,
	itemSize: i64,
	data:     rawptr,
}

// Map structure
UmkaMap :: struct {
	internal1: rawptr,
	internal2: rawptr,
}

// Any structure
UmkaAny :: struct {
	data: rawptr,
	type: rawptr,
}

// Closure structure
UmkaClosure :: struct {
	entryOffset: i64,
	upvalue:     UmkaAny,
}

// Error structure
UmkaError :: struct {
	fileName: cstring,
	fnName:   cstring,
	line:     c.int,
	pos:      c.int,
	code:     c.int,
	msg:      cstring,
}

// Warning callback type
UmkaWarningCallback :: proc "c" (warning: ^UmkaError)

// External call parameter layout
UmkaExternalCallParamLayout :: struct {
	numParams:       i64,
	numResultParams: i64,
	numParamSlots:   i64,
	// firstSlotIndex is a flexible array member in C
	// Access it through pointer arithmetic in Odin
}

// Direct API bindings
foreign umkalib {
	umkaAlloc :: proc() -> rawptr ---
	umkaInit :: proc(umka: rawptr, fileName: cstring, sourceString: cstring, stackSize: c.int, reserved: rawptr, argc: c.int, argv: [^]cstring, fileSystemEnabled: bool, implLibsEnabled: bool, warningCallback: UmkaWarningCallback) -> bool ---
	umkaCompile :: proc(umka: rawptr) -> bool ---
	umkaRun :: proc(umka: rawptr) -> c.int ---
	umkaCall :: proc(umka: rawptr, fn: ^UmkaFuncContext) -> c.int ---
	umkaFree :: proc(umka: rawptr) ---
	umkaGetError :: proc(umka: rawptr) -> ^UmkaError ---
	umkaAlive :: proc(umka: rawptr) -> bool ---
	umkaAsm :: proc(umka: rawptr) -> cstring ---
	umkaAddModule :: proc(umka: rawptr, fileName: cstring, sourceString: cstring) -> bool ---
	umkaAddFunc :: proc(umka: rawptr, name: cstring, func: UmkaExternFunc) -> bool ---
	umkaGetFunc :: proc(umka: rawptr, moduleName: cstring, fnName: cstring, fn: ^UmkaFuncContext) -> bool ---
	umkaGetCallStack :: proc(umka: rawptr, depth: c.int, nameSize: c.int, offset: ^c.int, fileName: cstring, fnName: cstring, line: ^c.int) -> bool ---
	umkaSetHook :: proc(umka: rawptr, event: UmkaHookEvent, hook: UmkaHookFunc) ---
	umkaAllocData :: proc(umka: rawptr, size: c.int, onFree: UmkaExternFunc) -> rawptr ---
	umkaIncRef :: proc(umka: rawptr, ptr: rawptr) ---
	umkaDecRef :: proc(umka: rawptr, ptr: rawptr) ---
	umkaGetMapItem :: proc(umka: rawptr, umkaMap: ^UmkaMap, key: UmkaStackSlot) -> rawptr ---
	umkaMakeStr :: proc(umka: rawptr, str: cstring) -> cstring ---
	umkaGetStrLen :: proc(str: cstring) -> c.int ---
	umkaMakeDynArray :: proc(umka: rawptr, array: rawptr, type: rawptr, len: c.int) ---
	umkaGetDynArrayLen :: proc(array: rawptr) -> c.int ---
	umkaGetVersion :: proc() -> cstring ---
	umkaGetMemUsage :: proc(umka: rawptr) -> i64 ---
	umkaMakeFuncContext :: proc(umka: rawptr, closureType: rawptr, entryOffset: c.int, fn: ^UmkaFuncContext) ---
}


umkaGetParam :: proc(params: ^UmkaStackSlot, index: c.longlong) -> ^UmkaStackSlot {
	// Access the parameter layout at params[-4]
	paramLayoutPtr := cast(^rawptr)(cast(uintptr)params - 4 * size_of(UmkaStackSlot))
	paramLayout := cast(^UmkaExternalCallParamLayout)paramLayoutPtr^

	if index < 0 || index >= paramLayout.numParams - paramLayout.numResultParams - 1 {
		return nil
	}

	// Access firstSlotIndex array through pointer arithmetic
	firstSlotIndexPtr := cast(^i64)(cast(uintptr)paramLayout +
		size_of(UmkaExternalCallParamLayout))
	firstSlotIndex := cast([^]i64)firstSlotIndexPtr

	offset := firstSlotIndex[index + 1] // + 1 to skip upvalues
	return cast(^UmkaStackSlot)(cast(uintptr)params + uintptr(offset * size_of(UmkaStackSlot)))
}

umkaGetUpvalue :: proc(params: ^UmkaStackSlot) -> ^UmkaAny {
	// Access the parameter layout at params[-4]
	paramLayoutPtr := cast(^rawptr)(cast(uintptr)params - 4 * size_of(UmkaStackSlot))
	paramLayout := cast(^UmkaExternalCallParamLayout)paramLayoutPtr^

	// Access firstSlotIndex array through pointer arithmetic
	firstSlotIndexPtr := cast(^i64)(cast(uintptr)paramLayout +
		size_of(UmkaExternalCallParamLayout))
	firstSlotIndex := cast([^]i64)firstSlotIndexPtr

	offset := firstSlotIndex[0]
	return cast(^UmkaAny)(cast(uintptr)params + uintptr(offset * size_of(UmkaStackSlot)))
}

umkaGetResult :: proc(params: ^UmkaStackSlot, result: ^UmkaStackSlot) -> ^UmkaStackSlot {
	// Access the parameter layout at params[-4]
	paramLayoutPtr := cast(^rawptr)(cast(uintptr)params - 4 * size_of(UmkaStackSlot))
	paramLayout := cast(^UmkaExternalCallParamLayout)paramLayoutPtr^

	if paramLayout.numResultParams == 1 {
		// Access firstSlotIndex array through pointer arithmetic
		firstSlotIndexPtr := cast(^i64)(cast(uintptr)paramLayout +
			size_of(UmkaExternalCallParamLayout))
		firstSlotIndex := cast([^]i64)firstSlotIndexPtr

		offset := firstSlotIndex[paramLayout.numParams - 1]
		resultPtr := cast(^rawptr)(cast(uintptr)params + uintptr(offset * size_of(UmkaStackSlot)))
		umka_stack_slot_set(result, resultPtr^)
	}
	return result
}

umkaGetInstance :: proc(result: ^UmkaStackSlot) -> rawptr {
	return umka_stack_slot_get(result, rawptr)
}
