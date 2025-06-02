# Umka-Odin

Odin bindings for the [Umka](https://github.com/vtereshkov/umka-lang) programming language - a statically typed embeddable scripting language.

## Features

- Complete Umka API bindings for Odin
- Cross-platform support (Windows, Linux, macOS ARM64/x64)
- Generic stack slot helpers for type-safe parameter passing
- External function registration
- Module system support
- Memory management utilities

## Usage

```odin
package example

import umka "./src"
import "core:c"
import "core:fmt"
import "core:strings"

main :: proc() {
    // Allocate Umka instance
    instance := umka.umkaAlloc()
    defer umka.umkaFree(instance)
    
    // Initialize with Umka source code
    source := `
        fn add(a: int, b: int): int {
            return a + b
        }
    `
    source_cstr := strings.clone_to_cstring(source)
    defer delete(source_cstr)
    
    umka.umkaInit(instance, "main.um", source_cstr, 1024*1024, nil, 0, nil, false, true, nil)
    umka.umkaCompile(instance)
    
    // Get function and call it
    fn_context: umka.UmkaFuncContext
    umka.umkaGetFunc(instance, nil, "add", &fn_context)
    
    // Set parameters
    params := cast([^]umka.UmkaStackSlot)fn_context.params
    umka.umka_stack_slot_set(&params[0], 4)
    umka.umka_stack_slot_set(&params[1], 6)
    
    // Call function
    umka.umkaCall(instance, &fn_context)
    
    // Get result
    result := umka.umka_stack_slot_get(fn_context.result, int)
    fmt.printf("Result: %d\n", result) // Output: Result: 10
}
```

## Building

Run tests with:
```bash
odin test tests -out:tests.bin
```

## Dependencies

- Umka library (included in `lib/` directory)
- Odin compiler

## License

This project provides bindings to the Umka language. See the [Umka repository](https://github.com/vtereshkov/umka-lang) for Umka's license.