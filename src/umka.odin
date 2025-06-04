package umka

import "core:c"
import "core:fmt"


// Platform-specific library imports
when ODIN_OS == .Windows {foreign import umkalib "../lib/windows/umkalib.lib"}
when ODIN_OS == .Linux {foreign import umkalib "../lib/linux/libumka.a"}
when ODIN_OS == .Darwin && ODIN_ARCH == .amd64 {foreign import umkalib "../lib/macos/libumka.a"}
when ODIN_OS ==
	.Darwin && ODIN_ARCH == .arm64 {foreign import umkalib "../lib/macos-arm64/libumka.a"}


StackSlot :: struct #raw_union {
	intVal:    i64,
	uintVal:   u64,
	ptrVal:    rawptr,
	realVal:   f64,
	real32Val: f32,
}

@(private)
set :: proc(slot: ^StackSlot, val: $T) {
	when T == i64 {
		slot.intVal = val
	} else when T == u64 {
		slot.uintVal = val
	} else when T == rawptr {
		slot.ptrVal = val
	} else when T == f64 {
		slot.realVal = val
	} else when T == f32 {
		slot.real32Val = val
	} else {
		fmt.println("Unsupported type for StackSlot set: ", typeid(T))
		panic("Unsupported type for StackSlot set")
	}
}

@(private)
get :: proc(slot: ^StackSlot, $T: typeid) -> T {
	when T == i64 {
		return slot.intVal
	} else when T == u64 {
		return slot.uintVal
	} else when T == rawptr {
		return slot.ptrVal
	} else when T == f64 {
		return slot.realVal
	} else when T == f32 {
		return slot.real32Val
	} else {
		fmt.println("Unsupported type for StackSlot get: ", typeid(T))
		panic("Unsupported type for StackSlot get")
	}
}
set_int :: proc(slot: ^StackSlot, val: i64) {
	set(slot, val)
}
get_int :: proc(slot: ^StackSlot) -> i64 {
	return get(slot, i64)
}
set_uint :: proc(slot: ^StackSlot, val: u64) {
	set(slot, val)
}
get_uint :: proc(slot: ^StackSlot) -> u64 {
	return get(slot, u64)
}
set_ptr :: proc(slot: ^StackSlot, val: rawptr) {
	set(slot, val)
}
get_ptr :: proc(slot: ^StackSlot) -> rawptr {
	return get(slot, rawptr)
}
set_real :: proc(slot: ^StackSlot, val: f64) {
	set(slot, val)
}
get_real :: proc(slot: ^StackSlot) -> f64 {
	return get(slot, f64)
}
set_real32 :: proc(slot: ^StackSlot, val: f32) {
	set(slot, val)
}
get_real32 :: proc(slot: ^StackSlot) -> f32 {
	return get(slot, f32)
}
// Function context structure
FuncContext :: struct {
	entryOffset: i64,
	params:      ^StackSlot,
	result:      ^StackSlot,
}

// External function callback type
ExternFunc :: proc "c" (params: ^StackSlot, result: ^StackSlot)

// Hook event enum
HookEvent :: enum c.int {
	UMKA_HOOK_CALL   = 0,
	UMKA_HOOK_RETURN = 1,
}

// Hook function callback type
HookFunc :: proc "c" (fileName: cstring, funcName: cstring, line: c.int)

// Dynamic array structure (generic equivalent)
DynArray :: struct {
	internal: rawptr,
	itemSize: i64,
	data:     rawptr,
}

Map :: struct {
	internal1: rawptr,
	internal2: rawptr,
}

Any :: struct {
	data: rawptr,
	type: rawptr,
}

Closure :: struct {
	entryOffset: i64,
	upvalue:     Any,
}

Error :: struct {
	fileName: cstring,
	fnName:   cstring,
	line:     c.int,
	pos:      c.int,
	code:     c.int,
	msg:      cstring,
}

WarningCallback :: proc "c" (warning: ^Error)


// Direct API bindings
foreign umkalib {
	umkaAlloc :: proc() -> rawptr ---
	umkaInit :: proc(umka: rawptr, fileName: cstring, sourceString: cstring, stackSize: c.int, reserved: rawptr, argc: c.int, argv: [^]cstring, fileSystemEnabled: bool, implLibsEnabled: bool, warningCallback: WarningCallback) -> bool ---
	umkaCompile :: proc(umka: rawptr) -> bool ---
	umkaRun :: proc(umka: rawptr) -> c.int ---
	umkaCall :: proc(umka: rawptr, fn: ^FuncContext) -> c.int ---
	umkaFree :: proc(umka: rawptr) ---
	umkaGetError :: proc(umka: rawptr) -> ^Error ---
	umkaAlive :: proc(umka: rawptr) -> bool ---
	umkaAsm :: proc(umka: rawptr) -> cstring ---
	umkaAddModule :: proc(umka: rawptr, fileName: cstring, sourceString: cstring) -> bool ---
	umkaAddFunc :: proc(umka: rawptr, name: cstring, func: ExternFunc) -> bool ---
	umkaGetFunc :: proc(umka: rawptr, moduleName: cstring, fnName: cstring, fn: ^FuncContext) -> bool ---
	umkaGetCallStack :: proc(umka: rawptr, depth: c.int, nameSize: c.int, offset: ^c.int, fileName: cstring, fnName: cstring, line: ^c.int) -> bool ---
	umkaSetHook :: proc(umka: rawptr, event: HookEvent, hook: HookFunc) ---
	umkaAllocData :: proc(umka: rawptr, size: c.int, onFree: ExternFunc) -> rawptr ---
	umkaIncRef :: proc(umka: rawptr, ptr: rawptr) ---
	umkaDecRef :: proc(umka: rawptr, ptr: rawptr) ---
	umkaGetMapItem :: proc(umka: rawptr, umkaMap: ^Map, key: StackSlot) -> rawptr ---
	umkaMakeStr :: proc(umka: rawptr, str: cstring) -> cstring ---
	umkaGetStrLen :: proc(str: cstring) -> c.int ---
	umkaMakeDynArray :: proc(umka: rawptr, array: rawptr, type: rawptr, len: c.int) ---
	umkaGetDynArrayLen :: proc(array: rawptr) -> c.int ---
	umkaGetVersion :: proc() -> cstring ---
	umkaGetMemUsage :: proc(umka: rawptr) -> i64 ---
	umkaMakeFuncContext :: proc(umka: rawptr, closureType: rawptr, entryOffset: c.int, fn: ^FuncContext) ---
	umkaGetUpvalue :: proc(params: ^StackSlot, index: c.int) -> ^Any ---
	umkaGetParam :: proc(params: ^StackSlot, index: c.int) -> ^StackSlot ---
	umkaGetResult :: proc(params: ^StackSlot, result: ^StackSlot) -> ^StackSlot ---
}
