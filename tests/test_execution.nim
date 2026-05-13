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

proc runSourceWithLimits(source: string, callDepth, maxIter, maxTick: int): VM =
  result = runSource(source)
  result.maxCallDepth = callDepth
  result.maxIterations = maxIter
  result.maxTicks = maxTick
  discard result.run()

proc getVarInt(vm: VM, name: string): int64 =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkInt: v.intVal else: -999

proc getVarStr(vm: VM, name: string): string =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkStr: v.strVal else: ""


suite "execution - maxCallDepth":

  test "maxCallDepth not exceeded (runs fine)":
    let vm = runSourceWithLimits("set 0 >> x\nblock inc\n  add x 1 >> x\nend\nrun inc\nrun inc\n", 10, 0, 0)
    check vm.error == ""

  test "maxCallDepth exceeded on recursion":
    let vm = runSourceWithLimits("set 0 >> x\nblock recurse\n  add x 1 >> x\n  if x < 100\n    run recurse\n  end\nend\nrun recurse\n", 3, 0, 0)
    check vm.error.contains("max call depth exceeded")

  test "maxCallDepth zero means unlimited":
    let vm = runSourceWithLimits("set 0 >> x\nblock inc\n  add x 1 >> x\nend\nrun inc\nrun inc\n", 0, 0, 0)
    check vm.error == ""


suite "execution - maxIterations":

  test "maxIterations not exceeded (runs fine)":
    let vm = runSourceWithLimits("set 0 >> i\nwhile i < 5\n  add i 1 >> i\nend\n", 0, 100, 0)
    check vm.error == ""
    check getVarInt(vm, "i") == 5

  test "maxIterations exceeded in while":
    let vm = runSourceWithLimits("set 0 >> i\nwhile i < 100\n  add i 1 >> i\nend\n", 0, 3, 0)
    check vm.error.contains("max iterations exceeded")

  test "maxIterations exceeded in loop":
    let vm = runSourceWithLimits("set 0 >> i\nloop 100\n  add i 1 >> i\nend\n", 0, 3, 0)
    check vm.error.contains("max iterations exceeded")

  test "maxIterations exceeded in each":
    let vm = runSourceWithLimits("set 0 >> sum\neach [1, 2, 3, 4, 5, 6, 7, 8] >> n\n  add sum n >> sum\nend\n", 0, 3, 0)
    check vm.error.contains("max iterations exceeded")

  test "maxIterations zero means unlimited":
    let vm = runSourceWithLimits("set 0 >> i\nwhile i < 100\n  add i 1 >> i\nend\n", 0, 0, 0)
    check vm.error == ""
    check getVarInt(vm, "i") == 100


suite "execution - maxTicks":

  test "maxTicks enforced before each tick":
    let vm = runSourceWithLimits("set 1 >> a\nset 2 >> b\nset 3 >> c\n", 0, 0, 2)
    check vm.error.contains("max ticks exceeded")
    check getVarInt(vm, "a") == 1
    check getVarInt(vm, "b") == 2

  test "maxTicks zero means unlimited":
    let vm = runSourceWithLimits("set 1 >> a\nset 2 >> b\nset 3 >> c\n", 0, 0, 0)
    check vm.error == ""


suite "execution - serialization":

  test "serialize/deserialize round-trip variables":
    var vm = runSourceWithLimits("set 42 >> x\nset \"hello\" >> y\nset [1, 2, 3] >> z\n", 0, 0, 0)
    check vm.error == ""
    check getVarInt(vm, "x") == 42

    let state = saveState(vm)
    var p2 = newParser(tokenize(""))
    var vm2 = newVM(compile(p2.parse()))
    check loadState(vm2, state)
    check getVarInt(vm2, "x") == 42
    check getVarStr(vm2, "y") == "hello"

  test "serialize mid-script preserves ip":
    var vm = runSourceWithLimits("set 10 >> a\nset 20 >> b\nset 30 >> c\n", 0, 0, 0)
    # run to completion
    check getVarInt(vm, "a") == 10
    check getVarInt(vm, "b") == 20
    check getVarInt(vm, "c") == 30

    let state = saveState(vm)
    var p2 = newParser(tokenize("set 10 >> a\nset 20 >> b\nset 30 >> c\n"))
    var vm2 = newVM(compile(p2.parse()))
    check loadState(vm2, state)
    check getVarInt(vm2, "a") == 10
    check getVarInt(vm2, "b") == 20
    check getVarInt(vm2, "c") == 30

  test "serialize mid-loop and resume":
    let tokens = tokenize("set 0 >> i\nset 0 >> sum\nwhile i < 10\n  add i 1 >> i\n  add sum i >> sum\nend\n")
    var parser = newParser(tokens)
    let program = parser.parse()
    let compiled = compile(program)
    var vm = newVM(compiled)

    # tick manually a few times
    for j in 0 ..< 3:
      discard vm.tick()
    # now save state
    let state = saveState(vm)

    var vm2 = newVM(compiled)
    check loadState(vm2, state)
    discard vm2.run()
    check getVarInt(vm2, "i") == 10
    check getVarInt(vm2, "sum") == 55

  test "loadState on invalid json returns false":
    var p = newParser(tokenize(""))
    var vm = newVM(compile(p.parse()))
    check not loadState(vm, "not valid json")
    check vm.error.contains("failed to load state")
