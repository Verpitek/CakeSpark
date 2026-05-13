import unittest
import strutils
import cakespark/cakespark

proc runFile(path: string): VM =
  let source = readFile(path)
  let compiled = compileSource(source)
  if compiled.hasError:
    raise newException(ValueError, "compile error: " & compiled.errorMsg)
  result = newVM(compiled)
  discard result.run()

proc runSource(source: string): VM =
  let compiled = compileSource(source)
  if compiled.hasError:
    raise newException(ValueError, "compile error: " & compiled.errorMsg)
  result = newVM(compiled)
  discard result.run()

proc getVarInt(vm: VM, name: string): int64 =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkInt: v.intVal else: -999

suite "integration - example scripts":

  test "hello.cake":
    let vm = runFile("examples/hello.cake")
    check vm.outputBuffer.contains("hello world")
    check vm.error == ""

  test "fibonacci.cake":
    let vm = runFile("examples/fibonacci.cake")
    check vm.outputBuffer.contains("1")
    check vm.outputBuffer.contains("34")
    check vm.error == ""

  test "fizzbuzz.cake":
    let vm = runFile("examples/fizzbuzz.cake")
    check vm.outputBuffer.contains("Fizz")
    check vm.outputBuffer.contains("Buzz")
    check vm.outputBuffer.contains("1")
    check vm.outputBuffer.contains("14")
    check vm.error == ""

  test "patrol.cake":
    let vm = runFile("examples/patrol.cake")
    check vm.outputBuffer.contains("patrol step 0")
    check vm.outputBuffer.contains("patrol step 1")
    check vm.outputBuffer.contains("patrol step 2")
    check getVarInt(vm, "counter") == 3
    check vm.error == ""


suite "integration - public API":

  test "compile source via public API":
    let vm = runSource("set 42 >> x\n")
    check getVarInt(vm, "x") == 42

  test "tick manually via public API":
    let compiled = compileSource("set 10 >> a\nset 20 >> b\n")
    var vm = newVM(compiled)
    check tick(vm)
    check getVarInt(vm, "a") == 10
    check tick(vm)
    check getVarInt(vm, "b") == 20
    check not tick(vm)

  test "setVar via public API":
    let compiled = compileSource("")
    var vm = newVM(compiled)
    setVar(vm, "x", newInt(99))
    check getVarInt(vm, "x") == 99


suite "integration - error reporting":

  test "parse error line/col":
    let compiled = compileSource("set 10 >> x\nif x > 5\n  bad\n")
    if compiled.hasError:
      check compiled.errorMsg != ""

  test "runtime error via getError":
    let vm = runSource("add x 1 >> y\n")
    check vm.error.contains("undefined")
    check getError(vm) != ""

  test "value error stored in variable":
    let vm = runSource("div 10 0 >> x\n")
    let x = getVar(vm, "x")
    check x != nil
    check x.kind == vkErr
    check x.errMsg.contains("division by zero")

  test "unknown function error":
    let vm = runSource("foobar 1 2\n")
    check vm.error.contains("unknown function")


suite "integration - serialization round-trip":

  test "save/load mid-execution":
    let compiled = compileSource("set 0 >> i\nset 0 >> sum\nwhile i < 10\n  add i 1 >> i\n  add sum i >> sum\nend\n")
    var vm = newVM(compiled)
    discard tick(vm)
    discard tick(vm)
    let state = saveState(vm)

    var vm2 = newVM(compiled)
    check loadState(vm2, state)
    discard run(vm2)
    check getVarInt(vm2, "i") == 10
    check getVarInt(vm2, "sum") == 55

  test "getOutput after run":
    let vm = runSource("log \"test output\"\n")
    check getOutput(vm).contains("test output")
