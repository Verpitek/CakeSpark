import unittest
import strutils
import tables
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

proc getVarInt(vm: VM, name: string): int64 =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkInt: v.intVal else: -999

proc getVarStr(vm: VM, name: string): string =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkStr: v.strVal else: ""

proc getVarFloat(vm: VM, name: string): float64 =
  let v = getVar(vm, name)
  if v != nil and v.kind == vkFloat: v.floatVal else: -999.0

suite "peripheral - registration and property read":

  test "register peripheral and read property":
    var vm = runSource("set 0 >> x\n")
    var p = Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    )
    p.properties["health"] = PeripheralProperty(
      getter: proc(vm: VM): Value = newInt(100),
      hasSetter: false,
    )
    registerPeripheral(vm, "player", p)
    check vm.error == ""

  test "register with reserved name str fails":
    var vm = runSource("set 0 >> x\n")
    registerPeripheral(vm, "str", Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    ))
    check vm.error.contains("reserved name")

  test "register with reserved name arr fails":
    var vm = runSource("set 0 >> x\n")
    registerPeripheral(vm, "arr", Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    ))
    check vm.error.contains("reserved name")


suite "peripheral - property read / write":

  test "read peripheral property to variable":
    var vm = runSource("player.health >> hp\n")
    var p = Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    )
    p.properties["health"] = PeripheralProperty(
      getter: proc(vm: VM): Value = newInt(100),
      hasSetter: false,
    )
    registerPeripheral(vm, "player", p)
    discard vm.run()
    check getVarInt(vm, "hp") == 100

  test "write peripheral property":
    var stored = 0'i64
    var vm = runSource("set 100 >> player.health\n")
    var p = Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    )
    p.properties["health"] = PeripheralProperty(
      getter: proc(vm: VM): Value = newInt(stored),
      setter: proc(vm: var VM, val: Value) = (stored = val.intVal),
      hasSetter: true,
    )
    registerPeripheral(vm, "player", p)
    discard vm.run()
    check stored == 100

  test "write to read-only property errors":
    var vm = runSource("set 42 >> player.readonly\n")
    var p = Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    )
    p.properties["readonly"] = PeripheralProperty(
      getter: proc(vm: VM): Value = newInt(0),
      hasSetter: false,
    )
    registerPeripheral(vm, "player", p)
    discard vm.run()
    check vm.error.contains("read-only")

  test "read unknown peripheral property errors":
    var vm = runSource("player.unknown >> x\n")
    var p = Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    )
    registerPeripheral(vm, "player", p)
    discard vm.run()
    check vm.error.contains("unknown property")


suite "peripheral - method calls":

  test "call peripheral method":
    var vm = runSource("player.heal(50) >> result\n")
    var p = Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    )
    p.methods["heal"] = proc(vm: var VM, args: seq[Value]): Value =
      newInt(args[0].intVal + 10)
    registerPeripheral(vm, "player", p)
    discard vm.run()
    check getVarInt(vm, "result") == 60

  test "method call with multiple args":
    var vm = runSource("player.moveTo(10, 20) >> ok\n")
    var p = Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    )
    p.methods["moveTo"] = proc(vm: var VM, args: seq[Value]): Value =
      newInt(args[0].intVal + args[1].intVal)
    registerPeripheral(vm, "player", p)
    discard vm.run()
    check getVarInt(vm, "ok") == 30

  test "method call without pipe discards return":
    var vm = runSource("player.noop()\nset 42 >> x\n")
    var p = Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    )
    p.methods["noop"] = proc(vm: var VM, args: seq[Value]): Value =
      newInt(1)
    registerPeripheral(vm, "player", p)
    discard vm.run()
    check getVarInt(vm, "x") == 42

  test "unknown peripheral method errors":
    var vm = runSource("player.unknownMethod() >> x\n")
    var p = Peripheral(
      properties: initTable[string, PeripheralProperty](),
      methods: initTable[string, MethodHandler](),
    )
    registerPeripheral(vm, "player", p)
    discard vm.run()
    check vm.error.contains("unknown function")

  test "method call on unknown peripheral errors":
    var vm = runSource("nobody.something() >> x\n")
    discard vm.run()
    check vm.error.contains("unknown function")
