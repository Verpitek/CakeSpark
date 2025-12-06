# CAKESPARK SCRIPTING LANGUAGE MANUAL

## A Retro Coding Adventure

### "One Operation Per Line, Sir"

---

# PAGE 1: WELCOME TO CAKESPARK

Welcome, fellow programmer! You've just loaded one of the most straightforward scripting languages ever created. Whether you're 8 or 80, CakeSpark speaks a language you can understand.

## What is CakeSpark?

CakeSpark is a **tick-based interpreted OpCode scripting language** designed for predictable performance and ease of parsing. Think of it as giving a robot instructions—one command at a time, nice and clear.

**Key Philosophy:**
- **One operation per line** — Every line begins with an OpCode
- **Perfect for learning** — Every command does exactly what it says
- **Memory conscious** — You can manage memory if you need to

## OpCodes - The Command System

Every line of CakeSpark code begins with an **OpCode** (Operation Code). An OpCode tells CakeSpark what action to take:

```cakespark
SET 10 >> x        // SET is the OpCode
PRINT x            // PRINT is the OpCode
MATH x + 5 >> y    // MATH is the OpCode
IF x > 5 >> label  // IF is the OpCode
```

Common OpCodes include:
- `SET` — Store a value in a variable
- `PRINT` — Display output
- `MATH` — Perform calculations
- `IF` — Make a decision
- `JUMP` — Go to a labeled point
- `POINT` — Mark a location
- `FOR` — Start a loop
- `PROC` — Define a procedure

Think of OpCodes as verbs that tell your program what to do. Each line must start with one!

## The Three Types We Work With

CakeSpark has three main data types:

| Type | What It Is | Example |
|------|-----------|---------|
| **Number** | Integers and decimals | `42`, `3.14`, `-100` |
| **String** | Text | `"Hello World"`, `"CakeSpark"` |
| **List** | Multiple numbers together | `[1, 2, 3, 4, 5]` |

---

# PAGE 2: YOUR FIRST PROGRAM

Let's start simple. Here's the tiniest CakeSpark program:

```cakespark
PRINT "Hello, World!"
```

**Anatomy of this line:**
- `PRINT` is the **OpCode** (the command)
- `"Hello, World!"` is the argument (what to print)

**What happens:**
1. The `PRINT` OpCode displays text and automatically adds a newline

Let's try something with numbers:

```cakespark
SET 10 >> number1
SET 20 >> number2
MATH number1 + number2 >> result
PRINT result
```

**Breaking it down - Each line has an OpCode:**
1. `SET` OpCode: Store `10` in `number1`
2. `SET` OpCode: Store `20` in `number2`
3. `MATH` OpCode: Add them together and store in `result`
4. `PRINT` OpCode: Display the `result` (which is `30`)

> **INFO:** The `>>` symbol means "pipe this to" or "store in". It's the arrow that shows where data flows! Every line starts with an OpCode that describes what to do.

---

# PAGE 3: VARIABLES - YOUR STORAGE BOXES

Variables are like labeled storage boxes. You put things in them, label them with a name, and take them out when you need them.

## Creating Variables with SET

```cakespark
SET 10 >> myNumber
PRINT myNumber
```

This creates a box called `myNumber` and puts the number `10` in it.

## Quick Initialization

```cakespark
SET playerScore
```

Creates `playerScore` with value `0` (default).

## Copying Variables

```cakespark
SET 100 >> original
SET original >> copy
PRINT copy
```

## Variable Names

In CakeSpark, variable names use camelCase (no underscores or dashes):
- `health`, `damage`, `score` — Good!
- `x1`, `y2`, `temp` — Also fine
- `playerHealth`, `enemyDamage` — Perfect!
- `player_health` — Don't use underscores

> **CAUTION:** Don't start variable names with numbers: `player1Health` works, but `1playerHealth` doesn't.

---

# PAGE 4: MATH - MAKING COMPUTERS COUNT

## Basic Operations

```cakespark
MATH 5 + 3 >> result
PRINT result

MATH 10 - 4 >> result
PRINT result

MATH 6 * 7 >> result
PRINT result

MATH 20 / 4 >> result
PRINT result

MATH 17 % 5 >> result
PRINT result

MATH 2 ** 8 >> result
PRINT result
```

## Using Variables

```cakespark
SET 10 >> health
SET 5 >> damage
MATH health - damage >> newHealth
PRINT newHealth
```

## Single Operations (Unary)

Sometimes you just transform a single number:

```cakespark
MATH 16 sqrt >> root
MATH 100 abs >> positive
MATH 3.7 floor >> roundedDown
MATH 3.2 ceil >> roundedUp
MATH 3.14159 sin >> sineVal
MATH -42 abs >> absolute
```

## Complex Expressions

You can chain operations:

```cakespark
MATH 2 + 3 * 4 >> result

MATH 10 + 5 * 2 >> result

MATH 100 / 4 + 10 >> result
```

---

# PAGE 5: PRINTING OUTPUT

## Simple Printing

```cakespark
PRINT 42
PRINT "Hello!"
```

PRINT automatically adds a newline after each output.

## Printing Variables

```cakespark
SET 100 >> score
PRINT score
```

## Printing Lists

```cakespark
LIST_CREATE numbers
LIST_PUSH 1 >> numbers
LIST_PUSH 2 >> numbers
LIST_PUSH 3 >> numbers
PRINT numbers
```

> **INFO:** Each `PRINT` command outputs to a buffer on its own line. When your program finishes, you can read all outputs at once. That's how CakeSpark displays things!

---

# PAGE 6: CONTROL FLOW - JUMPING AROUND

## Points and Jumps

Use `POINT` to mark a location and `JUMP` to go there:

```cakespark
PRINT "Starting"
JUMP skipThis
PRINT "This won't show"
POINT skipThis
PRINT "Done"
```

**Output:**
```
Starting
Done
```

## The IF Statement - Making Decisions

```cakespark
SET 10 >> number
IF number > 5 >> bigNumber
PRINT "Small"
JUMP done
POINT bigNumber
PRINT "Big"
POINT done
```

**Comparison Operators:**
- `>` — Greater than
- `<` — Less than
- `==` — Equal to
- `!=` — Not equal to
- `>=` — Greater or equal
- `<=` — Less or equal

---

# PAGE 7: LOOPS - REPEATING ACTIONS

## The POINT/JUMP Loop

```cakespark
SET 0 >> counter
POINT loopStart
PRINT counter
INC counter
IF counter < 5 >> loopStart
PRINT "Done!"
```

**Output:**
```
0
1
2
3
4
Done!
```

## FOR Loop - The Easy Way

```cakespark
FOR i 0 5
  PRINT i
ENDFOR
```

**Output:**
```
0
1
2
3
4
```

> **INFO:** `FOR i 0 5` means "start at 0, count up to (but not including) 5". The variable `i` holds the current iteration number.

## Breaking and Continuing

```cakespark
FOR i 0 10
  IF i == 5 >> skipMe
  PRINT i
  JUMP nextIteration
  POINT skipMe
  CONTINUE
  POINT nextIteration
ENDFOR
```

- `BREAK` — Exit the loop immediately
- `CONTINUE` — Skip to next iteration

---

# PAGE 8: INCREMENT AND DECREMENT

Two shortcuts for common operations:

```cakespark
SET 10 >> counter
INC counter
PRINT counter

DEC counter
DEC counter
PRINT counter
```

**Perfect for:**
- Score counters
- Loop counters
- Health/mana bars

> **CAUTION:** `INC` and `DEC` only work with one variable at a time. For multiple increments, use `MATH counter + 5 >> counter` instead.

---

# PAGE 9: PROCEDURES - REUSABLE CODE

Functions! Procedures! Subroutines! CakeSpark calls them `PROC`:

```cakespark
PROC greet (name)
  PRINT "Hello, "
  PRINT name
ENDPROC

CALL greet ("Alice")
CALL greet ("Bob")
```

**Output:**
```
Hello, 
Alice
Hello, 
Bob
```

## Procedures That Return Values

```cakespark
PROC double (x)
  MATH x * 2 >> result
  RETURN result
ENDPROC

CALL double (5) >> doubled
PRINT doubled
```

## Multiple Parameters

```cakespark
PROC add (a, b)
  MATH a + b >> sum
  RETURN sum
ENDPROC

CALL add (3, 7) >> result
PRINT result
```

> **INFO:** Procedures have their own memory space. Variables created inside don't affect the outside world.

---

# PAGE 10: ADVANCED CONDITIONALS

## The NOT Operator

```cakespark
SET 0 >> flag
IF NOT flag >> isZero
PRINT "Flag is not zero"
JUMP done
POINT isZero
PRINT "Flag is zero"
POINT done
```

## AND Operator

Both conditions must be true:

```cakespark
SET 10 >> x
SET 20 >> y
IF x < 15 AND y > 10 >> bothTrue
PRINT "One or both false"
JUMP end
POINT bothTrue
PRINT "Both true!"
POINT end
```

## OR Operator

At least one condition must be true:

```cakespark
SET 5 >> health
IF health == 0 OR health < 0 >> dead
PRINT "Still alive!"
JUMP end
POINT dead
PRINT "You died!"
POINT end
```

---

# PAGE 11: LISTS - COLLECTION OF NUMBERS

## Creating Lists

```cakespark
LIST_CREATE myScores
PRINT myScores
```

## Adding to Lists

```cakespark
LIST_CREATE numbers
LIST_PUSH 10 >> numbers
LIST_PUSH 20 >> numbers
LIST_PUSH 30 >> numbers
PRINT numbers
```

## Getting From Lists

```cakespark
LIST_CREATE colorsCoded
LIST_PUSH 255 >> colorsCoded
LIST_PUSH 128 >> colorsCoded
LIST_PUSH 0 >> colorsCoded

LIST_GET colorsCoded 0 >> redValue
PRINT redValue
```

> **CAUTION:** List indices start at 0! The first element is at index 0, not 1.

---

# PAGE 12: LIST OPERATIONS

## Sorting Lists

```cakespark
LIST_CREATE scores
LIST_PUSH 50 >> scores
LIST_PUSH 10 >> scores
LIST_PUSH 30 >> scores

LIST_SORT scores min
PRINT scores

LIST_SORT scores max
PRINT scores
```

## List Length

```cakespark
LIST_CREATE items
LIST_PUSH 1 >> items
LIST_PUSH 2 >> items

LIST_LENGTH items >> count
PRINT count
```

## Finding Elements

```cakespark
LIST_CREATE searchList
LIST_PUSH 10 >> searchList
LIST_PUSH 20 >> searchList
LIST_PUSH 30 >> searchList

LIST_FIND searchList 20 >> position
PRINT position

LIST_CONTAINS searchList 20 >> found
PRINT found
```

## Removing From Lists

```cakespark
LIST_CREATE toRemove
LIST_PUSH 1 >> toRemove
LIST_PUSH 2 >> toRemove
LIST_PUSH 3 >> toRemove

LIST_REMOVE toRemove 1 >> removedValue
PRINT removedValue
PRINT toRemove
```

---

---

---

# PAGE 15: MEMORY MANAGEMENT

## Looking at Your Variables

```cakespark
SET 10 >> x
SET 20 >> y
SET 30 >> z

MEMDUMP
```

**Output:**
```
DUMPING MEMORY at line 5
  [GLOBAL MEMORY]
    x: 10
    y: 20
    z: 30
END OF MEMORY DUMP
```

---

# PAGE 16: TYPE CHECKING

## TYPEOF - Knowing What You Have

```cakespark
SET 42 >> number
SET "hello" >> text
LIST_CREATE items

TYPEOF number >> type1
TYPEOF text >> type2
TYPEOF items >> type3

PRINT type1
PRINT type2
PRINT type3
```

Perfect for debugging or handling mixed data.

---

# PAGE 17: TIMING

## TICK - Getting Elapsed Instructions

Every instruction is one "tick". You can check how many have passed:

```cakespark
TICK startTick
PRINT startTick

PRINT "Hello"
PRINT "World"

TICK endTick
MATH endTick - startTick >> elapsed
PRINT elapsed
```

## WAIT - Pause Execution

```cakespark
PRINT "Starting"
WAIT 1000
PRINT "Done waiting"
```

> **INFO:** This is useful in timing-sensitive applications. One tick = one operation.

---

# PAGE 18: BEST PRACTICES

### DO:

1. **Initialize before using:**
   ```cakespark
   SET 0 >> score
   ```

2. **Use clear camelCase names:**
   ```cakespark
   SET 100 >> playerHealth
   ```

3. **Comment complex sections:**
   ```cakespark
   // Calculate player's next action based on AI
   IF enemyHealth < 50 >> flee
   ```

4. **Validate bounds for lists:**
   ```cakespark
   LIST_LENGTH myList >> len
   IF index < len >> valid
   ```

5. **Use procedures to organize code:**
   ```cakespark
   PROC calculateDamage (base, modifier)
     MATH base * modifier >> result
     RETURN result
   ENDPROC
   ```

### DON'T:

1. **Use undefined variables:**
   ```cakespark
   PRINT undefinedVar
   ```

2. **Jump outside procedures:**
   ```cakespark
   PROC myProc
     JUMP outside
   ENDPROC
   POINT outside
   ```

3. **Divide by zero:**
   ```cakespark
   MATH 10 / 0 >> result
   ```

4. **Access invalid list indices:**
   ```cakespark
   LIST_CREATE list
   LIST_PUSH 1 >> list
   LIST_GET list 5 >> value
   ```

---

# PAGE 19: COMMON PATTERNS

## Pattern 1: Counter Loop

```cakespark
SET 0 >> i
POINT loop
PRINT i
INC i
IF i < 10 >> loop
```

## Pattern 2: Accumulator

```cakespark
SET 0 >> total
FOR i 1 10
  MATH total + i >> total
ENDFOR
PRINT total
```

## Pattern 3: Nested Loops

```cakespark
FOR row 0 3
  FOR col 0 3
    PRINT "."
  ENDFOR
ENDFOR
```

## Pattern 4: Conditional Math

```cakespark
SET 0 >> divisor
IF divisor == 0 >> skipDiv
MATH 100 / divisor >> result
JUMP doneDiv
POINT skipDiv
SET -1 >> result
POINT doneDiv
PRINT result
```

---

# PAGE 20: DEBUGGING TIPS

### Finding Problems

1. **Use MEMDUMP to see what's stored:**
   ```cakespark
   MEMDUMP
   ```

2. **Print intermediate values:**
   ```cakespark
   SET 10 >> x
   SET 20 >> y
   PRINT x
   MATH x + y >> z
   PRINT z
   ```

3. **Use TYPEOF to verify types:**
   ```cakespark
   TYPEOF suspectVar >> type
   PRINT type
   ```

4. **Trace your jumps:**
   ```cakespark
   PRINT "Before jump"
   JUMP target
   PRINT "Never printed"
   POINT target
   PRINT "After jump"
   ```

5. **Test procedures in isolation:**
   ```cakespark
   PROC brokenThing (x)
     PRINT x
     MATH x * 2 >> result
     RETURN result
   ENDPROC
   
   CALL brokenThing (5) >> test
   PRINT test
   ```

---

# PAGE 21: COMPLETE EXAMPLE - GUESS THE NUMBER

```cakespark
PROC getGuess (min, max)
  SET 42 >> guess
  RETURN guess
ENDPROC

PROC checkGuess (secret, guess)
  IF guess == secret >> correct
  IF guess > secret >> tooHigh
  PRINT "Too low!"
  RETURN 0
  
  POINT tooHigh
  PRINT "Too high!"
  RETURN 0
  
  POINT correct
  PRINT "Correct!"
  RETURN 1
ENDPROC

SET 42 >> secretNumber
SET 0 >> won

POINT gameLoop
IF won == 1 >> gameEnd

CALL getGuess (1, 100) >> playerGuess
CALL checkGuess (secretNumber, playerGuess) >> isCorrect

SET isCorrect >> won
JUMP gameLoop

POINT gameEnd
PRINT "Game over!"
```

---

# PAGE 22: ADVANCED TECHNIQUES

## Recursive Procedures

```cakespark
PROC factorial (n)
  IF n <= 1 >> base
  MATH n - 1 >> nMinus1
  CALL factorial (nMinus1) >> subResult
  MATH n * subResult >> final
  RETURN final
  
  POINT base
  RETURN 1
ENDPROC

CALL factorial (5) >> result
PRINT result
```

## State Machines

```cakespark
SET 0 >> state

POINT stateMachine
PRINT state

IF state == 0 >> stateIdle
IF state == 1 >> stateActive
IF state == 2 >> stateDone
JUMP stateMachine

POINT stateIdle
SET 1 >> state
JUMP stateMachine

POINT stateActive
SET 2 >> state
JUMP stateMachine

POINT stateDone
PRINT "Complete!"
```

---

# PAGE 23: QUICK REFERENCE TABLE

| OpCode | Does | Example |
|--------|------|---------|
| SET | Store a value | `SET 10 >> x` |
| MATH | Calculate | `MATH x + y >> z` |
| PRINT | Display output | `PRINT result` |
| IF | Conditional jump | `IF x > 5 >> label` |
| JUMP | Unconditional jump | `JUMP label` |
| POINT | Mark location | `POINT label` |
| FOR...ENDFOR | Count loop | `FOR i 0 10` |
| INC | Add 1 | `INC counter` |
| DEC | Subtract 1 | `DEC counter` |
| PROC...ENDPROC | Define procedure | `PROC add (a, b)` |
| CALL | Call procedure | `CALL add (3, 5) >> result` |
| RETURN | Exit procedure | `RETURN result` |
| LIST_CREATE | New list | `LIST_CREATE items` |
| LIST_PUSH | Add to list | `LIST_PUSH 10 >> items` |
| LIST_GET | Get from list | `LIST_GET items 0 >> first` |
| LIST_SORT | Sort list | `LIST_SORT items min` |
| MEMDUMP | Show memory | `MEMDUMP` |
| TYPEOF | Check type | `TYPEOF var >> type` |

---

# PAGE 24: QUICK REFERENCE - MATH OPERATORS

| Operator | Use | Example |
|----------|-----|---------|
| `+` | Add | `MATH 5 + 3 >> result` |
| `-` | Subtract | `MATH 10 - 4 >> result` |
| `*` | Multiply | `MATH 6 * 7 >> result` |
| `/` | Divide | `MATH 20 / 4 >> result` |
| `%` | Modulo/Remainder | `MATH 17 % 5 >> result` |
| `**` | Power | `MATH 2 ** 3 >> result` |
| `sqrt` | Square root | `MATH 16 sqrt >> result` |
| `abs` | Absolute value | `MATH -42 abs >> result` |
| `floor` | Round down | `MATH 3.7 floor >> result` |
| `ceil` | Round up | `MATH 3.2 ceil >> result` |
| `round` | Round nearest | `MATH 3.5 round >> result` |
| `sin` | Sine | `MATH 3.14 sin >> result` |
| `cos` | Cosine | `MATH 3.14 cos >> result` |
| `tan` | Tangent | `MATH 3.14 tan >> result` |
| `rand` | Random | `MATH 100 rand >> result` |

---

# PAGE 25: QUICK REFERENCE - COMPARISON OPERATORS

| Operator | Means | Example |
|----------|-------|---------|
| `>` | Greater than | `IF x > 10 >> label` |
| `<` | Less than | `IF x < 10 >> label` |
| `==` | Equal to | `IF x == 10 >> label` |
| `!=` | Not equal | `IF x != 10 >> label` |
| `>=` | Greater or equal | `IF x >= 10 >> label` |
| `<=` | Less or equal | `IF x <= 10 >> label` |
| `AND` | Both true | `IF a > 5 AND b < 10 >> label` |
| `OR` | Either true | `IF a > 5 OR b < 10 >> label` |
| `NOT` | Negate | `IF NOT flag >> label` |

---

# PAGE 26: TROUBLESHOOTING

### "Variable is not defined"
**Problem:** You used a variable before creating it.
```cakespark
PRINT undefined
```
**Solution:** Always SET first.
```cakespark
SET 0 >> variable
PRINT variable
```

### "Jump target not found"
**Problem:** You jumped to a POINT that doesn't exist.
```cakespark
JUMP missingLabel
```
**Solution:** Define the POINT first.
```cakespark
POINT missingLabel
PRINT "Found it!"
```

### "Out of bounds"
**Problem:** You accessed a list index that doesn't exist.
```cakespark
LIST_CREATE items
LIST_PUSH 1 >> items
LIST_GET items 5 >> value
```
**Solution:** Check bounds or use LIST_LENGTH first.

### "Type mismatch"
**Problem:** You used the wrong type of data.
```cakespark
LIST_CREATE items
MATH items + 5 >> result
```
**Solution:** Make sure you're using the right variable type.

---

# PAGE 27: MEMORY MANAGEMENT

### Use Lists Wisely

```cakespark
LIST_CREATE hugeList
FOR i 0 10000
  LIST_PUSH i >> hugeList
ENDFOR
```

Consider alternatives like processing and discarding instead of storing everything.

### Reuse Variables

```cakespark
SET 0 >> value
POINT loop
  MATH value + 1 >> value
  IF value < 100 >> loop

SET 0 >> value
```

---

# PAGE 28: PERFORMANCE TIPS

CakeSpark is FAST, but here are ways to make it faster:

### 1. Use FOR loops instead of POINT/JUMP
```cakespark
FOR i 0 1000
  PRINT i
ENDFOR
```

### 2. Use procedures for repeated code
```cakespark
PROC calculateDamage (base, modifier)
  MATH base * modifier >> result
  RETURN result
ENDPROC

CALL calculateDamage (10, 2) >> dmg1
CALL calculateDamage (15, 3) >> dmg2
```

### 3. Minimize nested loops
```cakespark
FOR i 0 100
  FOR j 0 100
  ENDFOR
ENDFOR
```

---

# PAGE 29: REAL-WORLD EXAMPLE - INVENTORY SYSTEM

```cakespark
LIST_CREATE inventory
SET 0 >> gold

PROC addItem (itemId)
  LIST_PUSH itemId >> inventory
ENDPROC

PROC addGold (amount)
  LIST_PUSH amount >> inventory
ENDPROC

PROC showInventory ()
  PRINT "=== INVENTORY ==="
  LIST_LENGTH inventory >> length
  
  FOR i 0 length
    LIST_GET inventory i >> item
    PRINT item
  ENDFOR
ENDPROC

CALL addItem (1)
CALL addItem (2)
CALL addGold (50)
CALL showInventory ()
```

---

# PAGE 30: FINAL WORDS

### Welcome to the CakeSpark Community

You've now got the knowledge to:
- Create variables and do math
- Make decisions with IF statements
- Loop and repeat
- Build procedures with PROC
- Work with lists and data structures
- Manage memory
- Debug when things go wrong

### Remember:
- **One operation per line** keeps things clear
- **Comments** are your friend
- **Test often** and debug methodically
- **Reuse code** with procedures
- **Manage memory** on constrained systems

### Next Steps:
1. Write a simple game
2. Build a calculator
3. Create a data organizer
4. Optimize for performance
5. Share your code!

---

**You are now a CakeSpark programmer!**

May your variables be defined and your loops fast.

"One operation per line, sir."

---

**Last Updated:** November 2025
**CakeSpark Version:** Latest
**Manual Style:** Beginner-friendly, retro-inspired
**Target Audience:** Everyone from kids to experienced programmers

---

**Questions? Issues? Want to contribute?**
Report at: https://github.com/sst/opencode
