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

proc varExists(vm: VM, name: string): bool =
  getVar(vm, name) != nil

proc isErr(vm: VM, name: string): bool =
  let v = getVar(vm, name)
  v != nil and v.kind == vkErr

suite "strings - str.len":

  test "str.len basic":
    let vm = runSource("str.len(\"hello\") >> n\n")
    check getVarInt(vm, "n") == 5

  test "str.len empty":
    let vm = runSource("str.len(\"\") >> n\n")
    check getVarInt(vm, "n") == 0

  test "str.len unicode":
    let vm = runSource("str.len(\"hello\") >> n\n")
    check getVarInt(vm, "n") == 5


suite "strings - str.get":

  test "str.get first char":
    let vm = runSource("str.get(\"hello\", 0) >> c\n")
    check getVarStr(vm, "c") == "h"

  test "str.get last char":
    let vm = runSource("str.get(\"hello\", 4) >> c\n")
    check getVarStr(vm, "c") == "o"

  test "str.get OOB":
    let vm = runSource("str.get(\"hi\", 5) >> x\n")
    check isErr(vm, "x")


suite "strings - str.cat":

  test "str.cat basic":
    let vm = runSource("str.cat(\"hello\", \" world\") >> s\n")
    check getVarStr(vm, "s") == "hello world"

  test "str.cat with empty":
    let vm = runSource("str.cat(\"\", \"abc\") >> s\n")
    check getVarStr(vm, "s") == "abc"


suite "strings - str.slice":

  test "str.slice basic":
    let vm = runSource("str.slice(\"hello\", 1, 4) >> s\n")
    check getVarStr(vm, "s") == "ell"

  test "str.slice full string":
    let vm = runSource("str.slice(\"hello\", 0, 5) >> s\n")
    check getVarStr(vm, "s") == "hello"

  test "str.slice OOB clamped":
    let vm = runSource("str.slice(\"hi\", 0, 99) >> s\n")
    check getVarStr(vm, "s") == "hi"

  test "str.slice empty result":
    let vm = runSource("str.slice(\"abc\", 2, 2) >> s\n")
    check getVarStr(vm, "s") == ""


suite "strings - str.find":

  test "str.find found":
    let vm = runSource("str.find(\"hello world\", \"world\") >> i\n")
    check getVarInt(vm, "i") == 6

  test "str.find not found":
    let vm = runSource("str.find(\"hello\", \"xyz\") >> i\n")
    check getVarInt(vm, "i") == -1

  test "str.find at start":
    let vm = runSource("str.find(\"abc\", \"a\") >> i\n")
    check getVarInt(vm, "i") == 0


suite "strings - str.upper / str.lower":

  test "str.upper basic":
    let vm = runSource("str.upper(\"hello\") >> s\n")
    check getVarStr(vm, "s") == "HELLO"

  test "str.lower basic":
    let vm = runSource("str.lower(\"HELLO\") >> s\n")
    check getVarStr(vm, "s") == "hello"

  test "str.upper mixed":
    let vm = runSource("str.upper(\"Hello World\") >> s\n")
    check getVarStr(vm, "s") == "HELLO WORLD"


suite "strings - str.split":

  test "str.split basic":
    let vm = runSource("str.split(\"a,b,c\", \",\") >> parts\n")
    let arr = getVarArr(vm, "parts")
    check arr.len == 3
    check arr[0].strVal == "a"
    check arr[1].strVal == "b"
    check arr[2].strVal == "c"

  test "str.split no match":
    let vm = runSource("str.split(\"hello\", \",\") >> parts\n")
    let arr = getVarArr(vm, "parts")
    check arr.len == 1
    check arr[0].strVal == "hello"

  test "str.split empty sep error":
    let vm = runSource("str.split(\"hello\", \"\") >> x\n")
    check isErr(vm, "x")


suite "strings - str.trim":

  test "str.trim basic":
    let vm = runSource("str.trim(\"  hello  \") >> s\n")
    check getVarStr(vm, "s") == "hello"

  test "str.trim no whitespace":
    let vm = runSource("str.trim(\"hello\") >> s\n")
    check getVarStr(vm, "s") == "hello"


suite "strings - str.join":

  test "str.join basic":
    let vm = runSource("str.split(\"a,b,c\", \",\") >> parts\nstr.join(parts, \"-\") >> s\n")
    check getVarStr(vm, "s") == "a-b-c"

  test "str.join empty array":
    let vm = runSource("set [] >> parts\nstr.join(parts, \",\") >> s\n")
    check getVarStr(vm, "s") == ""

  test "str.join non-str array error":
    let vm = runSource("set [1, 2, 3] >> nums\nstr.join(nums, \",\") >> s\n")
    check isErr(vm, "s")
