<img src="http://dev.verpitek.com:3000/_app/immutable/assets/favicon.CBf7ROhx.png" width=256>
# CakeSpark

A tick-based interpreted OpCode scripting language designed for predictable performance and ease of parsing.

![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![TypeScript](https://img.shields.io/badge/typescript-%23007ACC.svg?logo=typescript&logoColor=white)
![Status](https://img.shields.io/badge/status-active-success.svg)

## Features

- **One Operation Per Line**: Predictable execution model with strict syntax
- **High Performance**: Pre-compiled instructions and optimized execution
- **Extensible**: Easy-to-create custom OpCodes via module system
- **Built-in Types**: Numbers, Strings, and Lists with comprehensive operations
- **Procedures**: Isolated memory scopes with parameter passing and return values
- **List Operations**: Create, manipulate, and sort lists of numbers
- **Type Introspection**: Check variable types at runtime with `TYPEOF`
- **Debugging**: Memory dumps, statistics, and execution ticks

## Getting Started

### Basic Usage

```typescript
import { CakeSparkVM } from "./cakespark";

const vm1 = new CakeSparkVM();

let code: string = `
SET 10 >> num1
SET 20 >> num2
SET result
MATH num1 + num2 >> result
PRINT result`;

const program1 = vm1.run(vm1.compile(code));

while (program1.next().done === false) {
}

for (let line of vm1.buffer) {
  console.log(line);
}
```

## Language Overview

CakeSpark uses a simple, readable syntax where each line performs exactly one operation:

```cakespark
// Variables
SET 10 >> x
SET y        // Defaults to 0

// Math operations
MATH x + 20 >> result
MATH result sqrt >> root

// Control flow
IF x > 5 >> do_something
JUMP end

POINT do_something
PRINT "x is greater than 5"

POINT end
END
```

### Working with Lists

```cakespark
// Create and populate a list
LIST_CREATE numbers
LIST_PUSH 30 >> numbers
LIST_PUSH 10 >> numbers
LIST_PUSH 20 >> numbers

// Sort and access
LIST_SORT numbers min  // Sort ascending
LIST_GET numbers 0 >> smallest
PRINT smallest  // outputs: 10
```

### Procedures

```cakespark
PROC factorial (n) {
   IF n <= 1 >> base_case
   MATH n - 1 >> n_minus_1
   CALL factorial (n_minus_1) >> result
   MATH n * result >> final
   RETURN final
   
   POINT base_case
   RETURN 1
}

CALL factorial (5) >> result
PRINT result  // outputs: 120
```

## Core OpCodes

| OpCode | Description | Example |
|--------|-------------|---------|
| `SET` | Assign variable | `SET 10 >> x` or `SET x` |
| `MATH` | Math operations | `MATH x + y >> result` |
| `PRINT` | Output values | `PRINT result` or `PRINT "Hello"` |
| `IF` | Conditional jump | `IF x > 10 >> label` |
| `JUMP` | Unconditional jump | `JUMP start` |
| `POINT` | Define jump target | `POINT start` |
| `PROC` | Define procedure | `PROC add (a, b) { ... }` |
| `CALL` | Call procedure | `CALL add (1, 2) >> sum` |
| `LIST_*` | List operations | `LIST_PUSH 10 >> mylist` |

## Creating Custom OpCodes

Extend CakeSpark with your own operations:

```typescript
// mymodule.ts
import { CakeSparkVM } from 'cakespark';

export function registerWith(vm: CakeSparkVM): void {
  vm.registerOpCode("DOUBLE", (args, context) => {
    const inputVar = context.getVar(args[0], 0);
    if (inputVar.type === CakeSparkType.Number) {
      const doubled = Num(inputVar.value * 2);
      context.setVar(args[2], doubled);
    }
  });
}
```

Use in CakeSpark:
```cakespark
IMPORT "mymodule"
SET 5 >> x
DOUBLE x >> result
PRINT result  // outputs: 10
```

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the Sparc asm, BASIC and esoteric languages
- Built with TypeScript to save the people working on it from insanity
- Designed for educational purposes and embedded scripting scenarios

---

<p align="center">Made with insanity and sillyness by Verpitek</p>
