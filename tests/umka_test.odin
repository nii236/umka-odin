package test_umka

import umka "../src"
import "base:runtime"
import "core:c"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:testing"


@(test)
test_umka_basic_lifecycle :: proc(t: ^testing.T) {
	source := `
	fn add(a: int, b: int): int {
    	return a + b
	}
`


	source_cstr := strings.clone_to_cstring(source)
	defer delete(source_cstr)
	instance := prepare_vm(t, source_cstr)

	testing.expect(t, umka.umkaAlive(instance), "Instance should be alive after allocation")

	umka.umkaFree(instance)
	testing.expect(t, !umka.umkaAlive(instance), "Instance should not be alive after freeing")
}

@(test)
test_umka_version :: proc(t: ^testing.T) {
	version := umka.umkaGetVersion()
	testing.expect(t, version != nil, "umkaGetVersion should return non-nil version string")

	version_str := string(version)
	testing.expect(t, len(version_str) > 0, "Version string should not be empty")

	fmt.printf("Umka version: %s\n", version_str)
}

@(test)
test_umka_simple_program :: proc(t: ^testing.T) {
	source := `
	fn add(a: int, b: int): int {
    	return a + b
	}
`


	source_cstr := strings.clone_to_cstring(source)
	defer delete(source_cstr)
	instance := prepare_vm(t, source_cstr)

	fn_context: umka.UmkaFuncContext
	get_func_success := umka.umkaGetFunc(instance, nil, "add", &fn_context)
	testing.expect(t, get_func_success, "Should be able to get 'add' function after compilation")


	// Set parameters for the add function (4 + 6 = 10)
	param0 := cast([^]umka.UmkaStackSlot)fn_context.params
	umka.umka_stack_slot_set_int(&param0[0], 4)
	umka.umka_stack_slot_set_int(&param0[1], 6)

	// Call the function using umkaCall
	call_result := umka.umkaCall(instance, &fn_context)
	testing.expect(t, call_result == 0, "umkaCall should return 0 on success")

	// Get the result from the function context
	result_value := umka.umka_stack_slot_get_int(fn_context.result)
	testing.expect(
		t,
		result_value == 10,
		fmt.tprintf("Expected function result 10 (4+6), got %d", result_value),
	)

}

@(test)
test_umka_compilation_error :: proc(t: ^testing.T) {
	instance := umka.umkaAlloc()
	defer umka.umkaFree(instance)

	// Invalid Umka program that should fail to compile
	source := `
        fn main(): int {
            return undefined_variable // This should cause a compilation error
        }
    `


	source_cstr := strings.clone_to_cstring(source)
	defer delete(source_cstr)

	init_success := umka.umkaInit(
		instance,
		"error_test.um",
		source_cstr,
		1024 * 1024,
		nil,
		0,
		nil,
		false,
		true,
		nil,
	)

	testing.expect(t, init_success, "Init should succeed even with bad source")

	// This should fail
	compile_success := umka.umkaCompile(instance)
	testing.expect(t, !compile_success, "Compilation should fail for invalid source")

	// Check that we can get error information
	error := umka.umkaGetError(instance)
	testing.expect(t, error != nil, "Should have error information after failed compilation")

	if error != nil {
		fmt.printf("Expected compilation error: %s\n", error.msg)
		testing.expect(t, error.msg != nil, "Error message should not be nil")
		testing.expect(t, error.fileName != nil, "Error filename should not be nil")
		testing.expect(t, error.line > 0, "Error line should be positive")
	}
}

@(test)
test_umka_stack_slot_helpers :: proc(t: ^testing.T) {
	slot: umka.UmkaStackSlot

	// Test integer operations
	umka.umka_stack_slot_set_int(&slot, 12345)
	int_val := umka.umka_stack_slot_get_int(&slot)
	testing.expect(t, int_val == 12345, fmt.tprintf("Expected 12345, got %d", int_val))

	// Test unsigned integer operations
	umka.umka_stack_slot_set_uint(&slot, 67890)
	uint_val := umka.umka_stack_slot_get_uint(&slot)
	testing.expect(t, uint_val == 67890, fmt.tprintf("Expected 67890, got %d", uint_val))

	// Test real number operations
	umka.umka_stack_slot_set_real(&slot, 3.14159)
	real_val := umka.umka_stack_slot_get_real(&slot)
	testing.expect(
		t,
		abs(real_val - 3.14159) < 0.00001,
		fmt.tprintf("Expected ~3.14159, got %f", real_val),
	)

	// Test 32-bit real operations
	umka.umka_stack_slot_set_real32(&slot, 2.718)
	real32_val := umka.umka_stack_slot_get_real32(&slot)
	testing.expect(
		t,
		abs(f64(real32_val) - 2.718) < 0.001,
		fmt.tprintf("Expected ~2.718, got %f", real32_val),
	)

	// Test pointer operations
	test_ptr := rawptr(uintptr(0x12345678))
	umka.umka_stack_slot_set_ptr(&slot, test_ptr)
	ptr_val := umka.umka_stack_slot_get_ptr(&slot)
	testing.expect(t, ptr_val == test_ptr, "Pointer values should match")
}

@(test)
test_umka_memory_usage :: proc(t: ^testing.T) {
	source := `fn main(): int { return 0 }`
	source_cstr := strings.clone_to_cstring(source)
	defer delete(source_cstr)
	instance := prepare_vm(t, source_cstr)
	defer umka.umkaFree(instance)
	initial_usage := umka.umkaGetMemUsage(instance)
	testing.expect(t, initial_usage >= 0, "Memory usage should be non-negative")
}

@(test)
test_umka_string_functions :: proc(t: ^testing.T) {
	odin_test_str := "Hello, Umka!"
	umka_test_str := strings.clone_to_cstring(odin_test_str)
	defer delete(umka_test_str)

	source := `fn main(): int { return 0 }`
	source_cstr := strings.clone_to_cstring(source)
	defer delete(source_cstr)

	instance := prepare_vm(t, source_cstr)
	defer umka.umkaFree(instance)

	umka_str := umka.umkaMakeStr(instance, umka_test_str)
	testing.expect(t, umka_str != nil, "umkaMakeStr should return non-nil string")

	umka_str_len := umka.umkaGetStrLen(umka_str)
	odin_str_len := len(odin_test_str)
	testing.expect(
		t,
		int(umka_str_len) == odin_str_len,
		fmt.tprintf("Expected length %d, got %d: %s", odin_str_len, umka_str_len, odin_test_str),
	)
}

// External function for testing callbacks
test_extern_func :: proc "c" (params: ^umka.UmkaStackSlot, result: ^umka.UmkaStackSlot) {
	context = runtime.default_context()
	if params != nil && result != nil {
		input_val := umka.umka_stack_slot_get_int(params)
		umka.umka_stack_slot_set_int(result, input_val * 2)
	}
}

@(test)
test_umka_add_external_function :: proc(t: ^testing.T) {
	// Initialize Umka
	source := `
	fn doubleValue(x: int): int 
	fn main(): int { 
		return 0 
	}
	`


	source_cstr := strings.clone_to_cstring(source)
	defer delete(source_cstr)
	fns := map[string]umka.UmkaExternFunc{}
	fns["doubleValue"] = test_extern_func
	defer delete(fns)
	instance := prepare_vm(t, source_cstr, fns)
	defer umka.umkaFree(instance)


	fn_context: umka.UmkaFuncContext
	get_func_success := umka.umkaGetFunc(instance, nil, "doubleValue", &fn_context)
	testing.expect(
		t,
		get_func_success,
		"Should be able to get 'doubleValue' function after adding it",
	)

	param0 := cast([^]umka.UmkaStackSlot)fn_context.params
	umka.umka_stack_slot_set_int(&param0[0], 42) // Set input value to 42
	call_result := umka.umkaCall(instance, &fn_context)
	testing.expect(t, call_result == 0, "umkaCall should return 0 on success")

	result_value := umka.umka_stack_slot_get_int(fn_context.result)
	testing.expect(
		t,
		result_value == 84,
		fmt.tprintf("Expected function result 84 (42 * 2), got %d", result_value),
	)
}

// Hook function for testing
test_hook_calls: int = 0

test_hook_func :: proc "c" (fileName: cstring, funcName: cstring, line: c.int) {
	context = runtime.default_context()
	log.info("Hook called: file=%s, func=%s, line=%d", fileName, funcName, line)
	test_hook_calls += 1
}

@(test)
test_umka_add_module :: proc(t: ^testing.T) {
	instance := umka.umkaAlloc()
	testing.expect(t, instance != nil, "umkaAlloc should return non-nil instance")
	defer umka.umkaFree(instance)

	module_filename := "test_module.um"
	module_filename_cstr := strings.clone_to_cstring(module_filename)
	defer delete(module_filename_cstr)

	// Initialize Umka with a simple program
	main_source := fmt.tprintfln(
		`
		import "%s"
		fn main(): int {{
			return 0
		}
	`,
		module_filename,
	)


	main_source_cstr := strings.clone_to_cstring(main_source)
	defer delete(main_source_cstr)

	module_source := `
		fn helper*(): int {
			return 42
		}
	`


	main_filename := "main.um"

	module_source_cstr := strings.clone_to_cstring(module_source)
	defer delete(module_source_cstr)


	init_success := umka.umkaInit(
		instance,
		"main.um",
		main_source_cstr,
		1024 * 1024,
		nil,
		0,
		nil,
		false,
		true,
		nil,
	)

	testing.expect(t, init_success, "umkaInit should succeed with valid source")

	add_module_success := umka.umkaAddModule(instance, module_filename_cstr, module_source_cstr)
	testing.expect(t, add_module_success, "umkaAddModule should succeed with valid source")


	compile_success := umka.umkaCompile(instance)
	testing.expect(t, compile_success, "umkaCompile should succeed with valid source")
	if !compile_success {
		error := umka.umkaGetError(instance)
		if error != nil {
			log.errorf("Compilation error: %s\n", error.msg)
		}
	}

	// call module function
	fn_context: umka.UmkaFuncContext
	get_func_success := umka.umkaGetFunc(instance, module_filename_cstr, "helper", &fn_context)
	testing.expect(
		t,
		get_func_success,
		"Should be able to get 'helper' function after adding module",
	)
	// Call the helper function
	call_result := umka.umkaCall(instance, &fn_context)
	testing.expect(t, call_result == 0, "umkaCall should return 0 on success")
	result_value := umka.umka_stack_slot_get_int(fn_context.result)
	testing.expect(
		t,
		result_value == 42,
		fmt.tprintf("Expected function result 42 from helper, got %d", result_value),
	)

}


@(test)
test_umka_hooks :: proc(t: ^testing.T) {
	test_hook_calls = 0
	source := `
	fn helper(): int {
		return 21
	}
		`


	source_cstr := strings.clone_to_cstring(source)
	defer delete(source_cstr)
	instance := prepare_vm(t, source_cstr)
	defer umka.umkaFree(instance)

	umka.umkaSetHook(instance, umka.UmkaHookEvent.UMKA_HOOK_CALL, test_hook_func)

	fn_context: umka.UmkaFuncContext
	get_func_success := umka.umkaGetFunc(instance, nil, "helper", &fn_context)
	testing.expect(
		t,
		get_func_success,
		"Should be able to get 'helper' function after compilation",
	)
	testing.expect(t, get_func_success, "Function should be found after compilation")

	call_result := umka.umkaCall(instance, &fn_context)
	testing.expect(t, call_result == 0, "umkaCall should return 0 on success")

	result_value := umka.umka_stack_slot_get_int(fn_context.result)
	testing.expect(t, result_value == 21, "Expected function result 21 from helper")


	testing.expect(t, test_hook_calls > 0, "Hook function should have been called at least once")
}

abs :: proc(x: f64) -> f64 {
	return x if x >= 0 else -x
}


prepare_vm :: proc(
	t: ^testing.T,
	source: cstring,
	fns: map[string]umka.UmkaExternFunc = nil,
) -> rawptr {
	instance := umka.umkaAlloc()
	init_success := umka.umkaInit(
		instance,
		"main.um",
		source,
		1024 * 1024,
		nil,
		0,
		nil,
		false,
		true,
		nil,
	)
	testing.expect(t, init_success, "Init should succeed with valid source")

	for name, fn in fns {
		name_cstr := strings.clone_to_cstring(name)
		defer delete(name_cstr)
		add_func_success := umka.umkaAddFunc(instance, name_cstr, fn)
		testing.expect(t, add_func_success, "Adding external function should succeed")
	}

	compile_success := umka.umkaCompile(instance)
	testing.expect(t, compile_success, "Compilation should succeed with valid source")
	if !compile_success {
		error := umka.umkaGetError(instance)
		if error != nil {
			log.errorf("Compilation error: %s\n", error.msg)
		}
	}

	return instance
}
