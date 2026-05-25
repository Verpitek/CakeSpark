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

proc isErrVal(vm: VM, name: string): bool =
  let v = getVar(vm, name)
  v != nil and v.kind == vkErr

proc errMsg(vm: VM, name: string): string =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkErr: v.errMsg else: ""

proc getVarStr(vm: VM, name: string): string =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkStr: v.strVal else: ""

suite "byte-size targets - types":

  test "IntType matches compile flag":
    when CakesparkIntBits == 32:
      check sizeof(IntType) == 4
      check IntMax == 2147483647
      check IntMin == -2147483648
    elif CakesparkIntBits == 64:
      check sizeof(IntType) == 8
      check IntMax == 9223372036854775807
      check IntMin == -9223372036854775808

  test "FloatType matches compile flag":
    when not CakesparkNoFloat:
      when CakesparkFloatBits == 32:
        check sizeof(FloatType) == 4
      elif CakesparkFloatBits == 64:
        check sizeof(FloatType) == 8

  test "typeName reflects config":
    let vm = runSource("typeof 42 >> t\n")
    when CakesparkIntBits == 32:
      check getVarStr(vm, "t") == "i32"
    else:
      check getVarStr(vm, "t") == "int"

suite "byte-size targets - overflow detection":

  test "add overflow near IntMax":
    let vm = runSource("add " & $IntMax & " 1 >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("overflow")

  test "add safe near IntMax":
    let vm = runSource("add " & $IntMax & " 0 >> x\n")
    check getVarInt(vm, "x") == IntMax

  test "sub overflow near IntMin":
    let vm = runSource("sub " & $IntMin & " 1 >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("overflow")

  test "sub safe near IntMin":
    let vm = runSource("sub " & $IntMin & " 0 >> x\n")
    check getVarInt(vm, "x") == IntMin

  test "mul overflow":
    let vm = runSource("mul " & $(IntMax div 2 + 1) & " 2 >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("overflow")

  test "div overflow IntMin / -1":
    let vm = runSource("div " & $IntMin & " -1 >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("division by zero") or errMsg(vm, "x").contains("overflow")

  test "neg overflow IntMin":
    let vm = runSource("abs " & $IntMin & " >> x\n")
    check isErrVal(vm, "x")
    check errMsg(vm, "x").contains("overflow")

  test "normal arithmetic no overflow":
    let vm = runSource("add 100 200 >> x\nsub x 50 >> y\nmul y 3 >> z\ndiv z 5 >> w\n")
    check getVarInt(vm, "x") == 300
    check getVarInt(vm, "y") == 250
    check getVarInt(vm, "z") == 750
    check getVarInt(vm, "w") == 150

suite "byte-size targets - literal range checking":

  test "literal within range parses":
    let tokens = tokenize($IntMax)
    check tokens[0].typ == tkInt
    check tokens[0].intVal == IntMax

  test "literal below range errors":
    when CakesparkIntBits == 32:
      var lex = newLexer("3000000000")
      discard lex.nextToken()
      check lex.hasError
      check lex.errorMsg.contains("out of range")

  test "literal at IntMin parses":
    let tokens = tokenize($IntMin)
    check tokens[0].typ == tkInt
    check tokens[0].intVal == IntMin

suite "byte-size targets - shl/shr overflow":

  test "shl overflow":
    when CakesparkIntBits == 32:
      let vm = runSource("shl 1 32 >> x\n")
      check isErrVal(vm, "x")
      check errMsg(vm, "x").contains("overflow")
    elif CakesparkIntBits == 64:
      let vm = runSource("shl 1 64 >> x\n")
      check isErrVal(vm, "x")
      check errMsg(vm, "x").contains("overflow")

  test "shr overflow":
    when CakesparkIntBits == 32:
      let vm = runSource("shr 1 32 >> x\n")
      check isErrVal(vm, "x")
      check errMsg(vm, "x").contains("overflow")
    elif CakesparkIntBits == 64:
      let vm = runSource("shr 1 64 >> x\n")
      check isErrVal(vm, "x")
      check errMsg(vm, "x").contains("overflow")

  test "shl safe":
    let vm = runSource("shl 1 3 >> x\n")
    check getVarInt(vm, "x") == 8

  test "shr safe":
    let vm = runSource("shr 8 2 >> x\n")
    check getVarInt(vm, "x") == 2

suite "byte-size targets - nofloat":

  test "float literal errors on nofloat":
    when CakesparkNoFloat:
      var lex = newLexer("3.14")
      discard lex.nextToken()
      check lex.hasError
      check lex.errorMsg.contains("float")

  test "tofloat errors on nofloat":
    when CakesparkNoFloat:
      let tokens = tokenize("tofloat 42 >> x\n")
      var parser = newParser(tokens)
      let program = parser.parse()
      let compiled = compile(program)
      check compiled.hasError
      check compiled.errorMsg.contains("float")
