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
  if v != nil and v.kind == vkInt: v.intVal else: -999

proc getVarFloat(vm: VM, name: string): float64 =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkFloat: v.floatVal else: -999.0

proc getVarStr(vm: VM, name: string): string =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkStr: v.strVal else: ""

proc isErrVal(vm: VM, name: string): bool =
  let v = getVar(vm, name)
  v != nil and v.kind == vkErr

proc errMsg(vm: VM, name: string): string =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkErr: v.errMsg else: ""

suite "functions - arithmetic":

  test "mul integers":
    let vm = runSource("mul 3 4 >> x\n")
    check getVarInt(vm, "x") == 12

  test "mul floats":
    let vm = runSource("mul 3.5 2.0 >> x\n")
    check abs(getVarFloat(vm, "x") - 7.0) < 0.01

  test "mul mixed":
    let vm = runSource("mul 3 2.5 >> x\n")
    check abs(getVarFloat(vm, "x") - 7.5) < 0.01

  test "div integers":
    let vm = runSource("div 10 3 >> x\n")
    check getVarInt(vm, "x") == 3

  test "div floats":
    let vm = runSource("div 10.0 4.0 >> x\n")
    check abs(getVarFloat(vm, "x") - 2.5) < 0.01

  test "div by zero int":
    let vm = runSource("div 10 0 >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("division by zero")

  test "div by zero float":
    let vm = runSource("div 10.0 0.0 >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("division by zero")

  test "mod integers":
    let vm = runSource("mod 10 3 >> x\n")
    check getVarInt(vm, "x") == 1

  test "mod negative":
    let vm = runSource("mod -10 3 >> x\n")
    check getVarInt(vm, "x") == -1

  test "mod by zero":
    let vm = runSource("mod 10 0 >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("modulo by zero")

  test "mod float error":
    let vm = runSource("mod 10 3.0 >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("float operand not allowed")

  test "pow int":
    let vm = runSource("pow 2 3 >> x\n")
    check getVarInt(vm, "x") == 8

  test "pow float":
    let vm = runSource("pow 2.0 3.0 >> x\n")
    check abs(getVarFloat(vm, "x") - 8.0) < 0.01

  test "pow negative exp":
    let vm = runSource("pow 2 -1 >> x\n")
    check abs(getVarFloat(vm, "x") - 0.5) < 0.01

  test "sqrt int":
    let vm = runSource("sqrt 16 >> x\n")
    check getVarInt(vm, "x") == 4

  test "sqrt float":
    let vm = runSource("sqrt 2.0 >> x\n")
    check abs(getVarFloat(vm, "x") - 1.414) < 0.01

  test "sqrt negative":
    let vm = runSource("sqrt -1 >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("negative")

  test "abs int":
    let vm = runSource("abs -5 >> x\n")
    check getVarInt(vm, "x") == 5

  test "abs float":
    let vm = runSource("abs -3.14 >> x\n")
    check abs(getVarFloat(vm, "x") - 3.14) < 0.01

  test "min int":
    let vm = runSource("min 3 7 >> x\n")
    check getVarInt(vm, "x") == 3

  test "max int":
    let vm = runSource("max 3 7 >> x\n")
    check getVarInt(vm, "x") == 7

  test "min mixed":
    let vm = runSource("min 3 2.5 >> x\n")
    check abs(getVarFloat(vm, "x") - 2.5) < 0.01




suite "functions - bitwise":

  test "and":
    let vm = runSource("and 6 3 >> x\n")
    check getVarInt(vm, "x") == 2

  test "or":
    let vm = runSource("or 6 3 >> x\n")
    check getVarInt(vm, "x") == 7

  test "xor":
    let vm = runSource("xor 6 3 >> x\n")
    check getVarInt(vm, "x") == 5

  test "not":
    let vm = runSource("not 0 >> x\n")
    check getVarInt(vm, "x") == -1

  test "shl":
    let vm = runSource("shl 1 3 >> x\n")
    check getVarInt(vm, "x") == 8

  test "shr":
    let vm = runSource("shr 8 2 >> x\n")
    check getVarInt(vm, "x") == 2

  test "and float error":
    let vm = runSource("and 6 3.0 >> x\n")
    check isErrVal(vm, "x")


suite "functions - type conversion":

  test "toint from int":
    let vm = runSource("toint 42 >> x\n")
    check getVarInt(vm, "x") == 42

  test "toint from float":
    let vm = runSource("toint 3.7 >> x\n")
    check getVarInt(vm, "x") == 3

  test "toint from string":
    let vm = runSource("toint \"42\" >> x\n")
    check getVarInt(vm, "x") == 42

  test "toint invalid string":
    let vm = runSource("toint \"hello\" >> x\n")
    check isErrVal(vm, "x")

  test "tofloat from int":
    let vm = runSource("tofloat 42 >> x\n")
    check abs(getVarFloat(vm, "x") - 42.0) < 0.01

  test "tofloat from float":
    let vm = runSource("tofloat 3.14 >> x\n")
    check abs(getVarFloat(vm, "x") - 3.14) < 0.01

  test "tofloat from string":
    let vm = runSource("tofloat \"3.14\" >> x\n")
    check abs(getVarFloat(vm, "x") - 3.14) < 0.01

  test "tostr int":
    let vm = runSource("tostr 42 >> x\n")
    check getVarStr(vm, "x") == "42"

  test "tostr float":
    let vm = runSource("tostr 3.5 >> x\n")
    check getVarStr(vm, "x") == "3.5"

  test "tostr string":
    let vm = runSource("tostr \"hello\" >> x\n")
    check getVarStr(vm, "x") == "hello"


suite "functions - error propagation":

  test "err propagates through add":
    let vm = runSource("div 10 0 >> x\nadd x 5 >> y\n")
    check isErrVal(vm, "x")
    check isErrVal(vm, "y")

  test "err propagates through sub":
    let vm = runSource("div 10 0 >> x\nsub x 3 >> y\n")
    check isErrVal(vm, "x")
    check isErrVal(vm, "y")

  test "err propagates through mul":
    let vm = runSource("div 10 0 >> x\nmul x 2 >> y\n")
    check isErrVal(vm, "y")

  test "typeof returns err type":
    let vm = runSource("div 10 0 >> x\ntypeof x >> t\n")
    check getVarStr(vm, "t") == "err"


suite "functions - edge cases":

  test "add int overflow is error":
    let vm = runSource("add 9223372036854775807 1 >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("overflow")

  test "pow zero exponent":
    let vm = runSource("pow 5 0 >> x\n")
    check getVarInt(vm, "x") == 1
