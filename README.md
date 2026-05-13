# CakeSpark

Sandboxed scripting language VM — version 1.0.0

**Author:** Matas Petraitis (Verpitek MB)  
**License:** Prosperity Public License 3.0.0

---

## Quick Start

```bash
nimble build          # compile the VM
./cakespark           # start REPL
./cakespark hello.cake  # run a script
```

---

## The One Rule

Every line follows a single pattern:

```
function [arguments...] [>> destination]
```

The function receives arguments. If `>>` is present, the return value is stored in the destination. No expressions, no operator precedence, no nested calls.

```
set 10 >> x
add x 5 >> result
log "the answer is {result}"
player.heal(50)
rng 1 100 >> roll
```

---

## What CakeSpark Is Not

No classes, no closures, no modules, no async, no exceptions, no generics, no operator overloading, no macros, no file I/O, no threading, no standard library. If you need any of the above, use a different language.

---

## Examples

### Hello World
```
set "world" >> name
log "hello {name}"
```

### Fibonacci
```
set 0 >> a
set 1 >> b
set 0 >> i
while i < 8
  set a >> tmp
  set b >> a
  add tmp b >> b
  add i 1 >> i
  log "{b}"
end
```

### Named Blocks
```
block patrol
  log "patrol step {counter}"
  add counter 1 >> counter
end

loop 3
  run patrol
end
```

---

## Built-in Functions

### Arithmetic
`add`, `sub`, `mul`, `div`, `mod`, `pow`, `sqrt`, `abs`, `min`, `max`, `rng`

### Bitwise
`and`, `or`, `xor`, `not`, `shl`, `shr`

### Output
`log`, `halt`

### String Operations
`str.len`, `str.get`, `str.cat`, `str.slice`, `str.find`, `str.upper`, `str.lower`, `str.split`, `str.trim`, `str.join`

### Array Operations
`arr.new`, `arr.len`, `arr.get`, `arr.set`, `arr.push`, `arr.pop`, `arr.sort`, `arr.contains`

### Type Operations
`typeof`, `tostr`, `toint`, `tofloat`

---

## Control Flow

### Conditionals
```
if hp < 20
  player.heal(50)
elif hp > 80
  log "doing fine"
else
  log "meh"
end
```

### Loops
```
while i < 10       // condition-based
  add i 1 >> i
end

loop 5             // counted
  player.step()
end

each items >> item // iteration
  log "{item}"
end
```

### break / continue
Works inside `while`, `loop`, `each`.

---

## Blocks

Named reusable code chunks. Share the caller's scope — set inputs before `run`, read outputs after.

```
block apply_damage
  player.health >> hp
  sub hp damage >> hp
  set hp >> player.health
end

set 5 >> damage
run apply_damage
```

Blocks support forward references via two-pass compilation.

---

## Peripherals

The host exposes capabilities through namespaced peripherals with properties and methods:

```
player.health >> hp          // property read
set 100 >> player.health     // property write
player.heal(50)              // method call
player.getHealth() >> hp     // method call with capture
```

---

## Embedding (C API)

```c
#include "cakespark.h"

CakeVM* vm = cake_new((CakeLimits){0});
cake_compile(vm, "set 10 >> x\nlog \"hello {x}\"");
while (cake_tick(vm) == CAKE_RUNNING) {}
printf("%s\n", cake_get_output(vm));
cake_free(vm);
```

See `include/cakespark.h` for the full API: compile, tick, register functions/peripherals, get/set variables, save/load state.

---

## Execution Model

Tick-based — one line per `cake_tick()`. The host never loses control. Scripts cannot block or run away. Resource limits enforce hard budgets on variables, memory, call depth, iterations, and total ticks.

---

## Build & Test

```bash
nimble build        # compile VM
nimble test         # run all 173 tests
nimble test_vm      # run VM tests only
```

Implemented in Nim (≥ 2.0.0). Compiles to C — embeddable in any C/C++ application. No GC pressure on the host (ARC/ORC).

---

## License

[Prosperity Public License 3.0.0](LICENSE.md) — free for non-commercial use, 30-day commercial trial, paid license for ongoing commercial use.
