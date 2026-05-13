import unittest
import strutils
import cakespark/value
import cakespark/lexer
import cakespark/parser
import cakespark/compiler
import cakespark/vm

proc runSource(source: string): VM =
  let tokens = tokenize(source)
  var parser = newParser(tokens)
  let program = parser.parse()
  let compiled = compile(program)
  if compiled.hasError:
    raise newException(ValueError, "compile error: " & compiled.errorMsg)
  result = newVM(compiled)
  discard result.run()

proc compileHasError(source: string): string =
  let tokens = tokenize(source)
  var parser = newParser(tokens)
  let program = parser.parse()
  let compiled = compile(program)
  if compiled.hasError:
    return compiled.errorMsg
  return ""

proc getVarInt(vm: VM, name: string): int64 =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkInt: v.intVal else: -999

proc getVarStr(vm: VM, name: string): string =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkStr: v.strVal else: ""

proc varExists(vm: VM, name: string): bool =
  getVar(vm, name) != nil

suite "controlflow - break / continue in loops":

  test "break in while":
    let vm = runSource("set 0 >> i\nwhile i < 100\n  add i 1 >> i\n  if i == 5\n    break\n  end\nend\n")
    check getVarInt(vm, "i") == 5
    check vm.error == ""

  test "break in loop":
    let vm = runSource("set 0 >> i\nloop 10\n  add i 1 >> i\n  if i == 3\n    break\n  end\nend\n")
    check getVarInt(vm, "i") == 3
    check vm.error == ""

  test "break in each":
    let vm = runSource("set 0 >> sum\neach [1, 2, 3, 4, 5] >> n\n  add sum n >> sum\n  if n == 3\n    break\n  end\nend\n")
    check getVarInt(vm, "sum") == 6
    check vm.error == ""

  test "continue in while":
    let vm = runSource("set 0 >> i\nset 0 >> evens\nwhile i < 10\n  add i 1 >> i\n  mod i 2 >> r\n  if r != 0\n    continue\n  end\n  add i evens >> evens\nend\n")
    check getVarInt(vm, "i") == 10
    check getVarInt(vm, "evens") == 30

  test "continue in loop":
    let vm = runSource("set 0 >> s\nloop 10\n  set 0 >> r\n  add s 1 >> s\n  mod s 2 >> r\n  if r != 0\n    continue\n  end\n  log \"even: {s}\"\nend\n")
    check getVarInt(vm, "s") == 10

  test "continue in each":
    let vm = runSource("set 0 >> sum\neach [1, 2, 3, 4, 5] >> n\n  mod n 2 >> r\n  if r == 0\n    continue\n  end\n  add sum n >> sum\nend\n")
    check getVarInt(vm, "sum") == 9


suite "controlflow - break / continue outside loop":

  test "break outside loop compile error":
    let err = compileHasError("break\n")
    check err.contains("outside any loop")

  test "continue outside loop compile error":
    let err = compileHasError("continue\n")
    check err.contains("outside any loop")

  test "break at top level":
    let err = compileHasError("set 0 >> x\nbreak\nset 1 >> y\n")
    check err.contains("outside any loop")

  test "continue in if without loop":
    let err = compileHasError("if 1 == 1\n  continue\nend\n")
    check err.contains("outside any loop")


suite "controlflow - if branch scoping":

  test "variable created in if-branch destroyed after branch":
    let vm = runSource("if 1 == 1\n  set 42 >> x\nend\n")
    check not varExists(vm, "x")

  test "variable created in else-branch destroyed after branch":
    let vm = runSource("if 1 == 0\n  set 1 >> x\nelse\n  set 2 >> x\nend\n")
    check not varExists(vm, "x")

  test "variable in if-branch not visible in else-branch":
    let vm = runSource("set 0 >> y\nif 1 == 0\n  set 1 >> x\nelse\n  set x >> y\nend\n")
    check vm.error.contains("undefined variable")

  test "each branch has independent scope":
    let vm = runSource("set 0 >> a\nif 1 == 0\n  set 1 >> a\nelif 1 == 0\n  set 2 >> a\nelse\n  set 3 >> a\nend\n")
    check getVarInt(vm, "a") == 3

  test "outer variable can be overwritten inside if":
    let vm = runSource("set 10 >> x\nif 1 == 1\n  set 42 >> x\nend\n")
    check getVarInt(vm, "x") == 42

  test "outer variable survives after branch":
    let vm = runSource("set 10 >> x\nif 1 == 1\n  set 99 >> inside\nend\n")
    check getVarInt(vm, "x") == 10
    check not varExists(vm, "inside")

  test "branch variable shadows outer but is destroyed":
    let vm = runSource("set 10 >> x\nif 1 == 1\n  set 5 >> x\nend\n")
    check getVarInt(vm, "x") == 5


suite "controlflow - nested loop scoping":

  test "inner loop scope isolated from outer":
    let vm = runSource("set 0 >> a\nloop 2\n  set 0 >> b\n  loop 2\n    set 42 >> c\n    add b 1 >> b\n  end\n  add a b >> a\nend\n")
    check getVarInt(vm, "a") == 4
    check not varExists(vm, "b")
    check not varExists(vm, "c")

  test "inner while inside outer loop":
    let vm = runSource("set 0 >> sum\nloop 2\n  set 0 >> i\n  while i < 3\n    add i 1 >> i\n    add sum i >> sum\n  end\nend\n")
    check getVarInt(vm, "sum") == 12

  test "break inner loop does not affect outer":
    let vm = runSource("set 0 >> outer\nset 0 >> inner\nloop 5\n  add outer 1 >> outer\n  set 0 >> j\n  loop 10\n    add j 1 >> j\n    add inner 1 >> inner\n    if j == 3\n      break\n    end\n  end\nend\n")
    check getVarInt(vm, "outer") == 5
    check getVarInt(vm, "inner") == 15


suite "controlflow - continue preserves scope":

  test "continue preserves loop scope across iterations":
    let vm = runSource("set 0 >> counter\nset 0 >> sum\nwhile counter < 5\n  add counter 1 >> counter\n  mod counter 2 >> r\n  if r == 0\n    continue\n  end\n  add sum counter >> sum\nend\n")
    check getVarInt(vm, "counter") == 5
    check getVarInt(vm, "sum") == 9

  test "continue in loop with inner if scope":
    let vm = runSource("set 0 >> total\nloop 5\n  add total 1 >> total\n  if total == 2\n    continue\n  end\n  set 99 >> temp\nend\n")
    check getVarInt(vm, "total") == 5
    check vm.error == ""


suite "controlflow - break cleans up scopes":

  test "break cleans up inner if scope":
    let vm = runSource("set 0 >> i\nwhile 1 == 1\n  add i 1 >> i\n  if i == 3\n    set 99 >> inner\n    break\n  end\nend\n")
    check getVarInt(vm, "i") == 3
    check not varExists(vm, "inner")

  test "break with nested scopes":
    let vm = runSource("set 0 >> x\nloop 10\n  add x 1 >> x\n  if x > 3\n    if x == 4\n      set 42 >> temp\n      break\n    end\n  end\nend\n")
    check getVarInt(vm, "x") == 4
    check not varExists(vm, "temp")

  test "break in inner loop preserves outer scope":
    let vm = runSource("set 0 >> i\nset 0 >> j\nwhile i < 10\n  add i 1 >> i\n  set 0 >> k\n  while k < 100\n    add k 1 >> k\n    if k == 3\n      set 99 >> inner_only\n      break\n    end\n  end\n  add j 1 >> j\n  if i == 3\n    break\n  end\nend\n")
    check getVarInt(vm, "i") == 3
    check getVarInt(vm, "j") == 3
    check not varExists(vm, "inner_only")
    check not varExists(vm, "k")
