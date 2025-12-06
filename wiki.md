# CakeSpark Scripting Language Documentation

Welcome to the **CakeSpark** scripting language! CakeSpark is a tick-based interpreted OpCode scripting language designed for predictable performance and ease of parsing.

## Table of Contents

1. [Language Overview](#language-overview)
2. [Key Features](#key-features)
3. [OpCode Reference](#opcode-reference)
4. [List Operations](#list-operations)
5. [Control Flow](#control-flow)
6. [Procedures](#procedures)
7. [Type Checking](#type-checking)
8. [Debugging](#debugging)
9. [Custom OpCodes](#custom-opcodes)
10. [Example Programs](#example-programs)

---

## Language Overview

By design, CakeSpark executes only **one operation per line of code**, making it highly predictable and easier to understand. The syntax is strict and specific, allowing for faster parsing and higher execution speed.

### Core Concepts

- **One operation per line**: Every line begins with an OpCode
- **Data piping**: The `>>` operator means "pipe to" or "store in"
- **Buffer output**: All output is saved to a buffer, not printed directly
- **Tick-based execution**: Each instruction is one "tick"

### Type System

CakeSpark has three internal types:

| Type | Description | Examples |
|------|-------------|----------|
| **Number** | JavaScript Number type | `42`, `3.14`, `-100` |
| **String** | Text strings | `"Hello"`, `"World"` |
| **List** | Arrays of numbers | `[1, 2, 3]`, `[10, 20]` |

---

## Key Features

### Data Piping

The `>>` operator pipes data to a destination:

```cakespark
SET 10 >> num1        // Pipe 10 to variable num1
MATH num1 + 5 >> result // Pipe calculation result to result
PRINT result          // Print the result
```

### Comments

Use `//` for inline or line comments:

```cakespark
// This is a comment
SET 10 >> x        // This is also a comment
PRINT x
```

### Buffer Output

CakeSpark does not print directly. All output goes to a buffer:

```javascript
const vm = new CakeSparkVM();
const instructions = vm.compile(code);
const program = vm.run(instructions);
while (program.next().done === false) {}

// Retrieve all output
for (let line of vm.buffer) {
  console.log(line);
}
```

---

## OpCode Reference

### Variable Operations

#### SET - Variable Assignment

Store values in variables. If only a variable name is provided, defaults to 0.

**Syntax:**
```
SET (Number/variable) >> <variable>
SET <variable>
```

**Examples:**
```cakespark
SET 10 >> num1
SET num1 >> result
SET counter           // Sets counter to 0
SET "Hello" >> greeting
```

---

### Arithmetic & Math

#### MATH - Mathematical Operations

Perform calculations on numbers. Supports both binary and unary operators.

**Syntax (Binary):**
```
MATH <expr> <operator> <expr> >> <result>
```

**Syntax (Unary):**
```
MATH <expr> <operator> >> <result>
```

**Binary Operators:** `+`, `-`, `*`, `/`, `%`, `**`, `min`, `max`

**Unary Operators:** `sqrt`, `log`, `floor`, `ceil`, `sin`, `cos`, `tan`, `rand`, `abs`, `round`, `log10`, `exp`

**Examples:**
```cakespark
MATH 10 + 20 >> result
MATH num1 * num2 >> product
MATH 16 sqrt >> root
MATH a * 2 + b / c >> complex
```

#### INC - Increment

Increment a variable by 1.

**Syntax:**
```
INC <variable>
```

**Example:**
```cakespark
SET 10 >> counter
INC counter    // counter is now 11
```

#### DEC - Decrement

Decrease a variable by 1.

**Syntax:**
```
DEC <variable>
```

**Example:**
```cakespark
SET 10 >> counter
DEC counter    // counter is now 9
```

---

### Output

#### PRINT - Print to Buffer

Output values to the buffer. Handles numbers, strings, variables, and lists.

**Syntax:**
```
PRINT <Number/variable/"string">
```

**Examples:**
```cakespark
PRINT 42
PRINT myVariable
PRINT "Hello World!"
PRINT myList      // Displays as [1,2,3]
```

---

## Control Flow

### Jump Operations

#### POINT - Define Jump Location

Mark a named location for jumping.

**Syntax:**
```
POINT <name>
```

**Example:**
```cakespark
POINT loop_start
PRINT "Loop iteration"
INC counter
IF counter < 5 >> loop_start
```

#### JUMP - Unconditional Jump

Jump to a labeled point unconditionally.

**Syntax:**
```
JUMP <name>
```

**Example:**
```cakespark
JUMP skip_this
PRINT "This won't print"
POINT skip_this
PRINT "This will print"
```

#### IF - Conditional Jump

Jump to a point based on a condition.

**Syntax:**
```
IF <expr> <operator> <expr> >> <point>
```

**Comparison Operators:** `>`, `<`, `==`, `!=`, `>=`, `<=`

**Logical Operators:** `AND`, `OR`, `NOT`

**Examples:**
```cakespark
IF x > 10 >> big
PRINT "x is small or equal to 10"
JUMP done
POINT big
PRINT "x is bigger than 10"
POINT done

// With logical operators
IF x > 5 AND y < 20 >> both_true
IF x == 0 OR y == 0 >> zero_check
IF NOT flag >> is_false
```

---

### Loops

#### FOR / ENDFOR - Loop Structure

Execute code multiple times with an iterator variable.

**Syntax:**
```
FOR <variable> <start> <end>
  // Loop body
ENDFOR
```

**Important:** Loop iterates from start to end-1 (end is exclusive).

**Example:**
```cakespark
FOR i 0 5
  PRINT i
ENDFOR
// Output: 0, 1, 2, 3, 4

FOR i 1 10 2
  PRINT i
ENDFOR
// Output: 1, 3, 5, 7, 9
```

#### BREAK - Exit Loop

Exit a FOR loop immediately.

**Syntax:**
```
BREAK
```

**Example:**
```cakespark
FOR i 0 10
  IF i == 5 >> break_loop
  PRINT i
  JUMP continue
  POINT break_loop
  BREAK
  POINT continue
ENDFOR
```

#### CONTINUE - Skip to Next Iteration

Skip to the next iteration of a loop.

**Syntax:**
```
CONTINUE
```

---

#### END - Terminate Program

Stop program execution.

**Syntax:**
```
END
```

---

## Procedures

### PROC / ENDPROC - Define Procedures

Define reusable code blocks with isolated memory scope.

**Syntax:**
```
PROC <name> (<parameters>)
  // Procedure body
ENDPROC
```

**Important Notes:**
- Procedures have their own isolated variable memory
- Cannot jump outside procedure boundaries
- Parameters are passed by value

**Example:**
```cakespark
PROC add (a, b)
  MATH a + b >> sum
  RETURN sum
ENDPROC

PROC greet (name)
  PRINT "Hello, "
  PRINT name
ENDPROC

CALL add (5, 3) >> result
PRINT result       // outputs: 8

CALL greet ("Alice")
// outputs: Hello,
// outputs: Alice
```

### RETURN - Return from Procedure

Exit a procedure and optionally return a value.

**Syntax:**
```
RETURN <Number/variable>
RETURN
```

**Example:**
```cakespark
PROC double (x)
  MATH x * 2 >> doubled
  RETURN doubled
ENDPROC

PROC noReturn ()
  PRINT "Done"
  RETURN
ENDPROC
```

### CALL - Call Procedure

Execute a procedure with arguments and store return value.

**Syntax:**
```
CALL <procName> (<args>) >> <resultVar>
CALL <procName> (<args>)
```

**Example:**
```cakespark
CALL add (10, 20) >> result
CALL greet ("World")
CALL square (5) >> squared
PRINT squared      // outputs: 25
```

---

## List Operations

### LIST_CREATE - Create List

Initialize an empty list.

**Syntax:**
```
LIST_CREATE <listName>
```

**Example:**
```cakespark
LIST_CREATE numbers
LIST_CREATE scores
```

### LIST_PUSH - Add Element

Append a number to the end of a list.

**Syntax:**
```
LIST_PUSH <Number/variable> >> <list>
```

**Example:**
```cakespark
LIST_CREATE items
LIST_PUSH 10 >> items
LIST_PUSH 20 >> items
LIST_PUSH 30 >> items
```

### LIST_SET - Set Element

Update a value at a specific index.

**Syntax:**
```
LIST_SET <value> <index> >> <list>
```

**Example:**
```cakespark
LIST_CREATE colors
LIST_PUSH 255 >> colors
LIST_PUSH 128 >> colors
LIST_SET 64 0 >> colors    // Changes first element to 64
```

### LIST_GET - Get Element

Retrieve a value from a specific index.

**Syntax:**
```
LIST_GET <list> <index> >> <variable>
```

**Example:**
```cakespark
LIST_CREATE numbers
LIST_PUSH 10 >> numbers
LIST_PUSH 20 >> numbers
LIST_GET numbers 0 >> first
PRINT first        // outputs: 10
```

### LIST_LENGTH - Get List Size

Get the number of elements in a list.

**Syntax:**
```
LIST_LENGTH <list> >> <result>
```

**Example:**
```cakespark
LIST_CREATE items
LIST_PUSH 1 >> items
LIST_PUSH 2 >> items
LIST_LENGTH items >> len
PRINT len          // outputs: 2
```

### LIST_SORT - Sort List

Sort list in ascending (min) or descending (max) order.

**Syntax:**
```
LIST_SORT <list> <min|max>
```

**Example:**
```cakespark
LIST_CREATE scores
LIST_PUSH 50 >> scores
LIST_PUSH 10 >> scores
LIST_PUSH 30 >> scores
LIST_SORT scores min       // [10, 30, 50]
LIST_SORT scores max       // [50, 30, 10]
```

### LIST_REVERSE - Reverse List

Reverse the order of list elements.

**Syntax:**
```
LIST_REVERSE <list> >> <result>
```

### LIST_FIND / LIST_INDEX_OF - Find Element

Get the index of an element (returns -1 if not found).

**Syntax:**
```
LIST_FIND <list> <value> >> <result>
LIST_INDEX_OF <list> <value> >> <result>
```

### LIST_CONTAINS - Check if Contains Value

Check if list contains a value (returns 1 or 0).

**Syntax:**
```
LIST_CONTAINS <list> <value> >> <result>
```

### LIST_REMOVE - Remove Element

Remove element at index and return the removed value.

**Syntax:**
```
LIST_REMOVE <list> <index> >> <result>
```

---

## Type Checking

### TYPEOF - Check Variable Type

Get the type of a variable at runtime.

**Syntax:**
```
TYPEOF <variable> >> <result>
```

**Returns:** `"number"`, `"string"`, `"list"`, or `"undefined"`

**Example:**
```cakespark
SET 42 >> num
SET "hello" >> str
LIST_CREATE mylist

TYPEOF num >> type1
TYPEOF str >> type2
TYPEOF mylist >> type3
TYPEOF undefined_var >> type4

PRINT type1    // outputs: number
PRINT type2    // outputs: string
PRINT type3    // outputs: list
PRINT type4    // outputs: undefined
```

---

## Debugging

### MEMDUMP - Dump Memory

Display all variables in memory (global and procedure-local).

**Syntax:**
```
MEMDUMP
```

**Example:**
```cakespark
SET 10 >> x
SET 20 >> y
MEMDUMP
```

**Output:**
```
DUMPING MEMORY at line 3
  [GLOBAL MEMORY]
    x: 10
    y: 20
END OF MEMORY DUMP
```

### TICK - Get Instruction Counter

Get the current execution tick (instruction count).

**Syntax:**
```
TICK <variable>
```

**Example:**
```cakespark
TICK start
PRINT start      // Current tick position
```

### NOP - No Operation

Placeholder instruction that does nothing.

**Syntax:**
```
NOP
```

---

## Advanced Features

### WAIT - Pause Execution

Pause execution for a specified number of ticks.

**Syntax:**
```
WAIT <Number/variable>
```

**Example:**
```cakespark
PRINT "Starting"
WAIT 1000
PRINT "Done waiting"
```

---

## Custom OpCodes

Extend CakeSpark with custom operations.

### Module Structure

Create a TypeScript module with a `registerWith` function:

```typescript
import { CakeSparkVM, OpCodeHandler } from './cakespark';

export function registerWith(vm: CakeSparkVM): void {
  vm.registerOpCode("MY_OP", (args, context) => {
    // Your implementation
    // args: string[] - Operation arguments
    // context: InterpreterContext - Access to VM state
  });
}
```

### InterpreterContext

```typescript
export interface InterpreterContext {
  buffer: string[];                              // Output buffer
  variableMemory: Map<string, Variable>;         // Global variables
  procVariableMemory: Map<string, Variable>;     // Procedure variables
  procLock: boolean;                             // Inside procedure?
  getVar: (name: string, line: number) => Variable;
  setVar: (name: string, value: Variable) => void;
}
```

### Variable Types

```typescript
const Num = (value: number): Variable => ({ type: 0, value });
const Str = (value: string): Variable => ({ type: 1, value });
const List = (value: number[]): Variable => ({ type: 2, value });
```

### Example: Custom DOUBLE OpCode

```typescript
export function registerWith(vm: CakeSparkVM): void {
  vm.registerOpCode("DOUBLE", (args, context) => {
    // DOUBLE varName >> result
    const input = context.getVar(args[0], 0);
    if (input.type === 0) {  // Number type
      const doubled = Num(input.value * 2);
      context.setVar(args[2], doubled);
    }
  });
}
```

Usage in CakeSpark:
```cakespark
IMPORT "mymodule"
SET 5 >> x
DOUBLE x >> result
PRINT result    // outputs: 10
```

---

## Example Programs

### Simple Counter

```cakespark
SET 0 >> counter
POINT loop
  PRINT counter
  INC counter
  IF counter < 10 >> loop
END
```

### Factorial Calculator

```cakespark
PROC factorial (n)
  IF n <= 1 >> base
  MATH n - 1 >> n_minus_1
  CALL factorial (n_minus_1) >> sub_result
  MATH n * sub_result >> final
  RETURN final
  
  POINT base
  RETURN 1
ENDPROC

SET 5 >> input
CALL factorial (input) >> result
PRINT result    // outputs: 120
END
```

### Fibonacci Sequence

```cakespark
SET 0 >> a
SET 1 >> b
SET 0 >> counter

POINT loop
  PRINT a
  MATH a + b >> temp
  SET b >> a
  SET temp >> b
  INC counter
  IF counter < 10 >> loop
END
```

### List Processing

```cakespark
// Create and populate list
LIST_CREATE numbers
LIST_PUSH 50 >> numbers
LIST_PUSH 10 >> numbers
LIST_PUSH 30 >> numbers

// Find and print
LIST_LENGTH numbers >> len
FOR i 0 len
  LIST_GET numbers i >> value
  PRINT value
ENDFOR

// Sort and display
LIST_SORT numbers min
PRINT "Sorted:"
PRINT numbers
END
```

### Nested Loops

```cakespark
FOR row 0 3
  FOR col 0 3
    PRINT "."
  ENDFOR
  PRINT " "
ENDFOR
END
```

---

## Running CakeSpark

### Basic Usage

```javascript
import { CakeSparkVM } from "./cakespark";

const vm = new CakeSparkVM();

const code = `
SET 10 >> num1
SET 20 >> num2
MATH num1 + num2 >> result
PRINT result
`;

const instructions = vm.compile(code);
const program = vm.run(instructions);

while (program.next().done === false) {}

for (let line of vm.buffer) {
  console.log(line);
}
```

### State Persistence

Save and restore program state:

```javascript
const vm = new CakeSparkVM();
const instructions = vm.compile(code);
const program = vm.run(instructions);

// Run partial execution
for (let i = 0; i < 10; i++) {
  program.next();
}

// Save state
const savedState = vm.saveState(instructions);

// Load in new VM
const vm2 = new CakeSparkVM();
const restoredInstructions = vm2.loadState(savedState);
const program2 = vm2.run(restoredInstructions);

// Continue execution
while (program2.next().done === false) {}
```

---

## Performance Optimizations

CakeSpark includes transparent optimizations:

- **Pre-compiled instructions**: Jump targets cached during compilation
- **Inline math operations**: Common operators inlined for speed
- **Object pooling**: Stack frames for procedure calls reused
- **Batch execution**: Sequential non-blocking instructions processed together

---

## Error Handling

CakeSpark provides detailed error messages with:

- Line numbers where errors occurred
- Description of what went wrong
- Suggestions for fixing common issues

### Common Errors

- **Undefined variable**: Variable not set before use
- **Undefined jump point**: JUMP/IF referencing non-existent POINT
- **Out of scope jump**: Attempting to JUMP outside procedure boundaries
- **Type mismatch**: Using string/list where number expected
- **Invalid syntax**: Malformed OpCode usage
- **Out of bounds**: Accessing invalid list index

---

## Best Practices

1. **Initialize before using**: Always `SET` variables before use
2. **Comment your code**: Use `//` to explain complex sections
3. **Validate list bounds**: Check indices with `LIST_LENGTH`
4. **Use procedures**: Break logic into reusable `PROC` blocks
5. **Meaningful names**: Use clear variable and procedure names
6. **Test systematically**: Build and test incrementally

---

## Quick Reference

| OpCode | Purpose | Syntax |
|--------|---------|--------|
| SET | Store value | `SET 10 >> x` |
| MATH | Calculate | `MATH x + 5 >> result` |
| PRINT | Output | `PRINT result` |
| IF | Conditional jump | `IF x > 5 >> label` |
| JUMP | Unconditional jump | `JUMP label` |
| POINT | Mark location | `POINT label` |
| FOR/ENDFOR | Loop | `FOR i 0 10` |
| PROC/ENDPROC | Define procedure | `PROC add (a,b)` |
| CALL | Call procedure | `CALL add (3,5) >> r` |
| RETURN | Return value | `RETURN result` |
| LIST_CREATE | New list | `LIST_CREATE items` |
| LIST_PUSH | Add to list | `LIST_PUSH 10 >> items` |
| LIST_GET | Get from list | `LIST_GET items 0 >> x` |
| INC | Increment | `INC counter` |
| DEC | Decrement | `DEC counter` |
| TYPEOF | Check type | `TYPEOF x >> type` |
| MEMDUMP | Show memory | `MEMDUMP` |
| TICK | Get counter | `TICK tick` |

---

**Last Updated:** December 2025  
**CakeSpark Version:** 0.5.1  
**License:** Apache 2.0

