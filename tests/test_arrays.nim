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

proc getVarInt(vm: VM, name: string): int64 =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkInt: v.intVal else: -999

proc getVarStr(vm: VM, name: string): string =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkStr: v.strVal else: ""

proc getVarArr(vm: VM, name: string): seq[Value] =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkArr: v.arrVal else: @[]

proc isErr(vm: VM, name: string): bool =
  let v = getVar(vm, name)
  v != nil and v.kind == vkErr


suite "arrays - arr.new / arr.len":

  test "arr.new creates empty array":
    let vm = runSource("arr.new(10) >> a\narr.len(a) >> n\n")
    check getVarInt(vm, "n") == 0

  test "arr.len on literal":
    let vm = runSource("set [1, 2, 3] >> a\narr.len(a) >> n\n")
    check getVarInt(vm, "n") == 3

  test "arr.len on empty":
    let vm = runSource("set [] >> a\narr.len(a) >> n\n")
    check getVarInt(vm, "n") == 0


suite "arrays - arr.get / arr.set":

  test "arr.get basic":
    let vm = runSource("set [10, 20, 30] >> a\narr.get(a, 1) >> x\n")
    check getVarInt(vm, "x") == 20

  test "arr.get OOB":
    let vm = runSource("set [1, 2] >> a\narr.get(a, 5) >> x\n")
    check isErr(vm, "x")

  test "arr.get negative index":
    let vm = runSource("set [1, 2] >> a\narr.get(a, -1) >> x\n")
    check isErr(vm, "x")

  test "arr.set basic":
    let vm = runSource("set [10, 20, 30] >> a\narr.set(a, 1, 99)\narr.get(a, 1) >> x\n")
    check getVarInt(vm, "x") == 99

  test "arr.set OOB":
    let vm = runSource("set [1, 2] >> a\narr.set(a, 5, 42) >> x\n")
    check isErr(vm, "x")

  test "arr.set returns value":
    let vm = runSource("set [1, 2, 3] >> a\narr.set(a, 0, 42) >> x\n")
    check getVarInt(vm, "x") == 42


suite "arrays - arr.push / arr.pop":

  test "arr.push basic":
    let vm = runSource("set [] >> a\narr.push(a, 1)\narr.push(a, 2)\narr.len(a) >> n\n")
    check getVarInt(vm, "n") == 2

  test "arr.push returns new length":
    let vm = runSource("set [] >> a\narr.push(a, 42) >> n\n")
    check getVarInt(vm, "n") == 1

  test "arr.push type mismatch":
    let vm = runSource("set [] >> a\narr.push(a, 1)\narr.push(a, \"hi\") >> x\n")
    check isErr(vm, "x")

  test "arr.pop basic":
    let vm = runSource("set [1, 2, 3] >> a\narr.pop(a) >> x\narr.len(a) >> n\n")
    check getVarInt(vm, "x") == 3
    check getVarInt(vm, "n") == 2

  test "arr.pop empty error":
    let vm = runSource("set [] >> a\narr.pop(a) >> x\n")
    check isErr(vm, "x")

  test "arr.pop single element resets type":
    let vm = runSource("set [] >> a\narr.push(a, 1)\narr.pop(a) >> old\narr.push(a, \"hi\")\narr.get(a, 0) >> x\n")
    check getVarStr(vm, "x") == "hi"
    check vm.error == ""


suite "arrays - arr.sort":

  test "arr.sort ints":
    let vm = runSource("set [3, 1, 2] >> a\narr.sort(a)\narr.get(a, 0) >> x\narr.get(a, 2) >> y\n")
    check getVarInt(vm, "x") == 1
    check getVarInt(vm, "y") == 3

  test "arr.sort strings":
    let vm = runSource("set [\"c\", \"a\", \"b\"] >> a\narr.sort(a)\narr.get(a, 0) >> x\n")
    check getVarStr(vm, "x") == "a"

  test "arr.sort in-place":
    let vm = runSource("set [3, 1, 2] >> a\narr.sort(a) >> b\narr.len(b) >> n\n")
    check getVarInt(vm, "n") == 3


suite "arrays - arr.contains":

  test "arr.contains found":
    let vm = runSource("set [1, 2, 3] >> a\narr.contains(a, 2) >> r\n")
    check getVarInt(vm, "r") == 1

  test "arr.contains not found":
    let vm = runSource("set [1, 2, 3] >> a\narr.contains(a, 99) >> r\n")
    check getVarInt(vm, "r") == 0

  test "arr.contains type mismatch returns 0":
    let vm = runSource("set [1, 2, 3] >> a\narr.contains(a, \"hi\") >> r\n")
    check getVarInt(vm, "r") == 0

  test "arr.contains empty array":
    let vm = runSource("set [] >> a\narr.contains(a, 1) >> r\n")
    check getVarInt(vm, "r") == 0


suite "arrays - copy on assign":

  test "array copy on assign creates independent copy":
    let vm = runSource("set [1, 2, 3] >> a\nset a >> b\narr.set(a, 0, 99)\narr.get(a, 0) >> ax\narr.get(b, 0) >> bx\n")
    check getVarInt(vm, "ax") == 99
    check getVarInt(vm, "bx") == 1

  test "arr.push on copy does not affect original":
    let vm = runSource("set [1, 2] >> a\nset a >> b\narr.push(a, 3)\narr.len(a) >> alen\narr.len(b) >> blen\n")
    check getVarInt(vm, "alen") == 3
    check getVarInt(vm, "blen") == 2
