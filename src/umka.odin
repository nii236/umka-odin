package umka

import "core:c"
import "core:fmt"


// Platform-specific library imports
when ODIN_OS == .Windows {foreign import umkalib "../lib/windows/umkalib.lib"}
when ODIN_OS == .Linux {foreign import umkalib "../lib/linux/libumka.a"}
when ODIN_OS == .Darwin && ODIN_ARCH == .amd64 {foreign import umkalib "../lib/macos/libumka.a"}
when ODIN_OS ==
	.Darwin && ODIN_ARCH == .arm64 {foreign import umkalib "../lib/macos-arm64/libumka.a"}

// Stack slot union matching C API
UmkaStackSlot :: union {
	i64,
	u64,
	rawptr,
	f64,
	f32,
}
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
