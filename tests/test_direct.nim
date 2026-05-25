when not defined(cakesparkDirect):
  {.error: "this test must be compiled with -d:cakesparkDirect".}

import unittest
import strutils
import cakespark/cakespark

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

suite "direct mode - tick is no-op":

  test "tick returns false immediately":
    let compiled = compileSource("set 42 >> x\n")
    var vm = newVM(compiled)
    check tick(vm) == false

  test "run executes all instructions":
    let vm = runSource("set 42 >> x\nset 20 >> y\nadd x y >> z\n")
    check getVarInt(vm, "x") == 42
    check getVarInt(vm, "y") == 20
    check getVarInt(vm, "z") == 62
    check vm.error == ""

suite "direct mode - limits are ignored":

  test "maxTicks has no effect":
    let compiled = compileSource("set 1 >> a\nset 2 >> b\nset 3 >> c\n")
    var vm = newVM(compiled)
    vm.maxTicks = 1
    discard vm.run()
    check vm.error == ""
    check getVarInt(vm, "a") == 1
    check getVarInt(vm, "b") == 2
    check getVarInt(vm, "c") == 3

  test "maxIterations has no effect on loops":
    let vm = runSource("set 0 >> i\nwhile i < 100\n  add i 1 >> i\nend\n")
    # Would exceed maxIterations=3, but limits are ignored
    check getVarInt(vm, "i") == 100
    check vm.error == ""

  test "maxCallDepth has no effect":
    let vm = runSource("set 0 >> x\nblock recurse\n  add x 1 >> x\n  if x < 10\n    run recurse\n  end\nend\nrun recurse\n")
    check getVarInt(vm, "x") == 10
    check vm.error == ""

suite "direct mode - overflow still enforced":

  test "int overflow still errors":
    when CakesparkIntBits == 64:
      let vm = runSource("add " & $IntMax & " 1 >> x\n")
      let x = getVar(vm, "x")
      check x != nil
      check x.kind == vkErr
    elif CakesparkIntBits == 32:
      let vm = runSource("add 2147483647 1 >> x\n")
      let x = getVar(vm, "x")
      check x != nil
      check x.kind == vkErr

suite "direct mode - still runs correctly":

  test "complex script completes":
    let source = "set 0 >> sum\n" &
                 "set 0 >> i\n" &
                 "while i < 10\n" &
                 "  add i 1 >> i\n" &
                 "  add sum i >> sum\n" &
                 "end\n"
    let vm = runSource(source)
    check getVarInt(vm, "i") == 10
    check getVarInt(vm, "sum") == 55
    check vm.error == ""

  test "blocks work":
    let vm = runSource("set 0 >> x\nblock inc\n  add x 1 >> x\nend\nrun inc\nrun inc\nrun inc\n")
    check getVarInt(vm, "x") == 3
    check vm.error == ""
