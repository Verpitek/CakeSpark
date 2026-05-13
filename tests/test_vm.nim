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
  result = newVM(compiled)
  discard result.run()

proc getVarInt(vm: VM, name: string): int64 =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkInt:
    return v.intVal
  return -1

proc getVarStr(vm: VM, name: string): string =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkStr:
    return v.strVal
  return ""

suite "VM - variables":

  test "set and get":
    let vm = runSource("set 10 >> x\n")
    check getVarInt(vm, "x") == 10
    check vm.error == ""

  test "variable overwrite":
    let vm = runSource("set 10 >> x\nset 20 >> x\n")
    check getVarInt(vm, "x") == 20

  test "chain variables":
    let vm = runSource("set 10 >> x\nset x >> y\n")
    check getVarInt(vm, "x") == 10
    check getVarInt(vm, "y") == 10

  test "undefined variable error":
    let vm = runSource("add x 1 >> y\n")
    check vm.error.contains("undefined variable")


suite "VM - arithmetic":

  test "add integers":
    let vm = runSource("add 1 2 >> x\n")
    check getVarInt(vm, "x") == 3

  test "sub integers":
    let vm = runSource("sub 10 3 >> x\n")
    check getVarInt(vm, "x") == 7

  test "add with variable":
    let vm = runSource("set 5 >> a\nadd a 3 >> b\n")
    check getVarInt(vm, "b") == 8


suite "VM - log and halt":

  test "log output":
    let vm = runSource("log \"hello\"\n")
    check vm.outputBuffer.contains("hello")

  test "halt stops execution":
    let vm = runSource("set 1 >> x\nhalt\nset 2 >> y\n")
    check getVarInt(vm, "x") == 1
    check getVarInt(vm, "y") == -1

  test "halt with value":
    let vm = runSource("halt 0\n")
    check vm.halted


suite "VM - if":

  test "if true":
    let vm = runSource("set 0 >> x\nif 1 == 1\n  set 42 >> x\nend\n")
    check getVarInt(vm, "x") == 42

  test "if false":
    let vm = runSource("set 0 >> x\nif 1 == 0\n  set 42 >> x\nend\n")
    check getVarInt(vm, "x") == 0

  test "if else true":
    let vm = runSource("set 0 >> x\nif 1 == 1\n  set 1 >> x\nelse\n  set 2 >> x\nend\n")
    check getVarInt(vm, "x") == 1

  test "if else false":
    let vm = runSource("set 0 >> x\nif 1 == 0\n  set 1 >> x\nelse\n  set 2 >> x\nend\n")
    check getVarInt(vm, "x") == 2

  test "elif taken":
    let vm = runSource("set 0 >> x\nif 1 == 0\n  set 1 >> x\nelif 1 == 1\n  set 2 >> x\nelse\n  set 3 >> x\nend\n")
    check getVarInt(vm, "x") == 2

  test "variable in condition":
    let vm = runSource("set 5 >> x\nset 0 >> y\nif x > 3\n  set 100 >> y\nend\n")
    check getVarInt(vm, "y") == 100


suite "VM - while":

  test "while loop":
    let vm = runSource("set 0 >> i\nwhile i < 3\n  add i 1 >> i\nend\n")
    check getVarInt(vm, "i") == 3

  test "while never executed":
    let vm = runSource("set 0 >> i\nwhile i < 0\n  set 99 >> i\nend\n")
    check getVarInt(vm, "i") == 0


suite "VM - loop":

  test "loop count":
    let vm = runSource("set 0 >> i\nloop 3\n  add i 1 >> i\nend\n")
    check getVarInt(vm, "i") == 3

  test "loop zero":
    let vm = runSource("set 0 >> x\nloop 0\n  set 42 >> x\nend\n")
    check getVarInt(vm, "x") == 0


suite "VM - each":

  test "each array literal":
    let vm = runSource("set 0 >> sum\neach [1, 2, 3] >> n\n  add sum n >> sum\nend\n")
    check getVarInt(vm, "sum") == 6

  test "each empty array":
    let vm = runSource("set 0 >> sum\neach [] >> n\n  add sum 1 >> sum\nend\n")
    check getVarInt(vm, "sum") == 0


suite "VM - blocks":

  test "simple block call":
    let vm = runSource("set 0 >> x\nblock inc\n  add x 1 >> x\nend\nrun inc\n")
    check getVarInt(vm, "x") == 1

  test "block reads outer variable":
    let vm = runSource("set 5 >> a\nset 0 >> b\nblock double\n  set a >> b\nend\nrun double\n")
    check getVarInt(vm, "b") == 5

  test "block call multiple times":
    let vm = runSource("set 0 >> x\nblock inc\n  add x 1 >> x\nend\nrun inc\nrun inc\nrun inc\n")
    check getVarInt(vm, "x") == 3


suite "VM - break / continue":

  test "break in while":
    let vm = runSource("set 0 >> i\nwhile i < 100\n  add i 1 >> i\n  if i == 3\n    break\n  end\nend\n")
    check getVarInt(vm, "i") == 3

  test "continue in while":
    let vm = runSource("set 0 >> i\nset 0 >> evens\nwhile i < 6\n  add i 1 >> i\n  mod i 2 >> r\n  if r != 0\n    continue\n  end\n  add i evens >> evens\nend\n")
    check getVarInt(vm, "i") == 6
    check getVarInt(vm, "evens") == 12
    check vm.error == ""


suite "VM - typeof":

  test "typeof int":
    let vm = runSource("typeof 42 >> t\n")
    check getVarStr(vm, "t") == "int"
