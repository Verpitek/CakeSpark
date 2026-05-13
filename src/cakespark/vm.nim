import cakespark/value
import cakespark/lexer
import cakespark/parser
import cakespark/compiler
import std/[tables, random, math, strutils, unicode, algorithm, json]

type
  ScopeFrame* = ref ScopeFrameObj
  ScopeFrameObj* = object
    vars*: Table[string, Value]
    parent*: ScopeFrame

  BuiltinFn* = proc(vm: var VM, args: seq[Value]): Value {.closure.}

  PropertyGetter* = proc(vm: VM): Value {.closure.}
  PropertySetter* = proc(vm: var VM, val: Value) {.closure.}
  MethodHandler* = proc(vm: var VM, args: seq[Value]): Value {.closure.}

  PeripheralProperty* = object
    getter*: PropertyGetter
    setter*: PropertySetter
    hasSetter*: bool

  Peripheral* = object
    properties*: Table[string, PeripheralProperty]
    methods*: Table[string, MethodHandler]

  LoopState* = object
    loopScope*: ScopeFrame
    innerLoopList*: int
    innerLoopHeaderIp*: int
    loopCounter*: int64
    loopTarget*: int64
    eachArray*: seq[Value]
    eachIndex*: int
    eachItemVar*: string

  VM* = object
    allInstructions*: seq[seq[Instruction]]
    blockIndex*: Table[string, int]
    currentList*: int
    ip*: int
    halted*: bool
    error*: string
    errorLine*, errorCol*: int

    scope*: ScopeFrame
    callStack*: seq[(int, int, ScopeFrame)]

    outputBuffer*: string

    builtins*: Table[string, BuiltinFn]

    peripherals*: Table[string, Peripheral]

    maxCallDepth*: int
    maxIterations*: int
    maxTicks*: int
    maxVariables*: int
    maxMemory*: int
    tickCount*: int
    iterationCount*: int

    loopStack*: seq[LoopState]

proc pushScope(vm: var VM) =
  vm.scope = ScopeFrame(vars: initTable[string, Value](), parent: vm.scope)

proc popScope(vm: var VM) =
  if vm.scope.parent != nil:
    vm.scope = vm.scope.parent

proc getVar*(vm: VM, name: string): Value =
  var frame = vm.scope
  while frame != nil:
    if name in frame.vars:
      return frame.vars[name]
    frame = frame.parent
  return nil

proc setVar*(vm: var VM, name: string, value: Value) =
  var frame = vm.scope
  while frame != nil:
    if name in frame.vars:
      frame.vars[name] = value
      return
    frame = frame.parent
  vm.scope.vars[name] = value

proc tostrVal(v: Value): string =
  case v.kind
  of vkInt: $v.intVal
  of vkFloat:
    var s = $v.floatVal
    if s.endsWith(".0"): s = s[0 ..< s.len - 2]
    return s
  of vkStr: v.strVal
  of vkArr:
    var parts: seq[string]
    for e in v.arrVal:
      parts.add(tostrVal(e))
    "[" & parts.join(", ") & "]"
  of vkErr: v.errMsg

proc resolveResolvedArg(vm: var VM, arg: ResolvedArg): Value =
  case arg.kind
  of rakInt:
    newInt(arg.intVal)
  of rakFloat:
    newFloat(arg.floatVal)
  of rakString:
    var s = ""
    for part in arg.strParts:
      if part.isInterp:
        let v = getVar(vm, part.varName)
        if v != nil:
          s.add(tostrVal(v))
      else:
        s.add(part.lit)
    newStr(s)
  of rakIdent:
    let v = getVar(vm, arg.varName)
    if v == nil:
      vm.error = "undefined variable '" & arg.varName & "'"
      return newErr(vm.error)
    return v
  of rakArray:
    var elems: seq[Value]
    for e in arg.elements:
      elems.add(resolveResolvedArg(vm, e))
    return newArr(elems)
  of rakTrue:
    newInt(1)
  of rakFalse:
    newInt(0)

proc resolveConditionArg(vm: var VM, arg: Arg): Value =
  case arg.kind
  of akInt:
    newInt(arg.intVal)
  of akFloat:
    newFloat(arg.floatVal)
  of akString:
    var s = ""
    for part in arg.strParts:
      if part.isInterp:
        let v = getVar(vm, part.varName)
        if v != nil:
          s.add(tostrVal(v))
      else:
        s.add(part.lit)
    newStr(s)
  of akIdent:
    let v = getVar(vm, arg.identName)
    if v == nil:
      vm.error = "undefined variable '" & arg.identName & "'"
      return newErr(vm.error)
    return v
  of akArray:
    var elems: seq[Value]
    for e in arg.arrayElems:
      elems.add(resolveConditionArg(vm, e))
    return newArr(elems)
  of akTrue:
    newInt(1)
  of akFalse:
    newInt(0)

proc cmpEq(l, r: Value): bool =
  if l.kind == vkInt and r.kind == vkInt: l.intVal == r.intVal
  elif l.kind == vkInt and r.kind == vkFloat: float64(l.intVal) == r.floatVal
  elif l.kind == vkFloat and r.kind == vkInt: l.floatVal == float64(r.intVal)
  elif l.kind == vkFloat and r.kind == vkFloat: l.floatVal == r.floatVal
  elif l.kind == vkStr and r.kind == vkStr: l.strVal == r.strVal
  elif l.kind == vkArr and r.kind == vkArr: false
  else: false

proc cmpLt(l, r: Value): bool =
  if l.kind == vkInt and r.kind == vkInt: l.intVal < r.intVal
  elif l.kind == vkInt and r.kind == vkFloat: float64(l.intVal) < r.floatVal
  elif l.kind == vkFloat and r.kind == vkInt: l.floatVal < float64(r.intVal)
  elif l.kind == vkFloat and r.kind == vkFloat: l.floatVal < r.floatVal
  elif l.kind == vkStr and r.kind == vkStr: l.strVal < r.strVal
  else: false

proc cmpGt(l, r: Value): bool =
  if l.kind == vkInt and r.kind == vkInt: l.intVal > r.intVal
  elif l.kind == vkInt and r.kind == vkFloat: float64(l.intVal) > r.floatVal
  elif l.kind == vkFloat and r.kind == vkInt: l.floatVal > float64(r.intVal)
  elif l.kind == vkFloat and r.kind == vkFloat: l.floatVal > r.floatVal
  elif l.kind == vkStr and r.kind == vkStr: l.strVal > r.strVal
  else: false

proc compareValues(vm: var VM, left, right: Value, op: TokenType): Value =
  if left == nil or right == nil:
    return newErr("cannot compare nil values")
  if left.kind == vkErr: return left
  if right.kind == vkErr: return right

  case op
  of tkEq: newInt(if cmpEq(left, right): 1 else: 0)
  of tkNeq: newInt(if not cmpEq(left, right): 1 else: 0)
  of tkLt: newInt(if cmpLt(left, right): 1 else: 0)
  of tkGt: newInt(if cmpGt(left, right): 1 else: 0)
  of tkLte: newInt(if not cmpGt(left, right): 1 else: 0)
  of tkGte: newInt(if not cmpLt(left, right): 1 else: 0)
  else: newErr("unknown comparison operator")

proc writeDest(vm: var VM, instr: Instruction, val: Value) =
  if not instr.hasDest:
    return
  if instr.destVar != "":
    setVar(vm, instr.destVar, val)
  elif instr.destPeripheral != "":
    if instr.destPeripheral notin vm.peripherals:
      vm.error = "unknown peripheral '" & instr.destPeripheral & "'"
      return
    if instr.destProperty notin vm.peripherals[instr.destPeripheral].properties:
      vm.error = "unknown property '" & instr.destProperty & "' on peripheral '" & instr.destPeripheral & "'"
      return
    let prop = vm.peripherals[instr.destPeripheral].properties[instr.destProperty]
    if not prop.hasSetter:
      vm.error = "property '" & instr.destProperty & "' is read-only"
      return
    prop.setter(vm, val)

proc executeCall(vm: var VM, instr: Instruction) =
  var resolvedArgs: seq[Value]
  for a in instr.args:
    resolvedArgs.add(resolveResolvedArg(vm, a))

  var fn: BuiltinFn
  var lookupName: string
  if instr.isMethod:
    lookupName = instr.peripheral & "." & instr.methodName
  else:
    lookupName = instr.funcName

  if lookupName in vm.builtins:
    fn = vm.builtins[lookupName]
  elif instr.isMethod and instr.peripheral in vm.peripherals and instr.methodName in vm.peripherals[instr.peripheral].methods:
    fn = vm.peripherals[instr.peripheral].methods[instr.methodName]
  else:
    vm.error = "unknown function '" & lookupName & "'"
    return

  let result = fn(vm, resolvedArgs)
  writeDest(vm, instr, result)

proc conditionIsTrue(vm: var VM, cond: Condition): bool =
  let v = compareValues(vm,
    resolveConditionArg(vm, cond.left),
    resolveConditionArg(vm, cond.right),
    cond.op,
  )
  if v.kind == vkErr:
    vm.error = v.errMsg
    return false
  result = v.kind == vkInt and v.intVal != 0

proc currentLoop(vm: VM): LoopState =
  vm.loopStack[^1]

proc getLoopHeader(vm: VM): Instruction =
  let ls = currentLoop(vm)
  if ls.innerLoopList >= 0 and ls.innerLoopList < vm.allInstructions.len:
    let instrs = vm.allInstructions[ls.innerLoopList]
    if ls.innerLoopHeaderIp < instrs.len:
      return instrs[ls.innerLoopHeaderIp]
  Instruction(kind: inkEnd, line: 0, col: 0)

proc executeTick(vm: var VM) =
  if vm.halted:
    return

  if vm.currentList >= vm.allInstructions.len:
    vm.halted = true
    return

  let instrs = vm.allInstructions[vm.currentList]
  if vm.ip >= instrs.len:
    vm.halted = true
    return

  let instr = instrs[vm.ip]
  vm.errorLine = instr.line
  vm.errorCol = instr.col

  case instr.kind
  of inkCall:
    executeCall(vm, instr)
    vm.ip.inc

  of inkIf:
    if conditionIsTrue(vm, instr.condition):
      vm.ip.inc
    else:
      vm.ip = instr.jumpTarget

  of inkElse:
    vm.ip = instr.jumpTarget

  of inkEnd:
    vm.ip.inc

  of inkWhile:
    if vm.loopStack.len == 0 or vm.loopStack[^1].innerLoopHeaderIp != vm.ip:
      pushScope(vm)
      vm.loopStack.add(LoopState(
        loopScope: vm.scope,
        innerLoopList: vm.currentList,
        innerLoopHeaderIp: vm.ip,
      ))
    if conditionIsTrue(vm, instr.condition):
      vm.ip.inc
    else:
      discard vm.loopStack.pop()
      popScope(vm)
      vm.ip = instr.jumpTarget

  of inkEndWhile:
    vm.iterationCount.inc
    if vm.maxIterations > 0 and vm.iterationCount > vm.maxIterations:
      vm.error = "max iterations exceeded"
      return
    vm.ip = instr.jumpTarget

  of inkLoop:
    if vm.loopStack.len == 0 or vm.loopStack[^1].innerLoopHeaderIp != vm.ip:
      pushScope(vm)
      var target: int64
      if instr.countName != "":
        let v = getVar(vm, instr.countName)
        if v == nil or v.kind != vkInt:
          vm.error = "loop count must be an integer"
          return
        target = v.intVal
      else:
        target = instr.countVal
      vm.loopStack.add(LoopState(
        loopScope: vm.scope,
        innerLoopList: vm.currentList,
        innerLoopHeaderIp: vm.ip,
        loopCounter: 0,
        loopTarget: target,
      ))

    if vm.loopStack[^1].loopCounter >= vm.loopStack[^1].loopTarget:
      discard vm.loopStack.pop()
      popScope(vm)
      vm.ip = instr.jumpTarget
    else:
      vm.ip.inc

  of inkEndLoop:
    vm.iterationCount.inc
    if vm.maxIterations > 0 and vm.iterationCount > vm.maxIterations:
      vm.error = "max iterations exceeded"
      return
    vm.loopStack[^1].loopCounter.inc
    if vm.loopStack[^1].loopCounter < vm.loopStack[^1].loopTarget:
      vm.ip = instr.jumpTarget
    else:
      discard vm.loopStack.pop()
      popScope(vm)
      vm.ip.inc

  of inkEach:
    if vm.loopStack.len == 0 or vm.loopStack[^1].innerLoopHeaderIp != vm.ip:
      pushScope(vm)
      var arr: seq[Value]
      if instr.arrayName != "":
        let v = getVar(vm, instr.arrayName)
        if v == nil or v.kind != vkArr:
          vm.error = "each requires an array"
          return
        arr = v.arrVal
      else:
        for a in instr.arrayLit:
          arr.add(resolveResolvedArg(vm, a))
      vm.loopStack.add(LoopState(
        loopScope: vm.scope,
        innerLoopList: vm.currentList,
        innerLoopHeaderIp: vm.ip,
        eachArray: arr,
        eachIndex: 0,
        eachItemVar: instr.itemVar,
      ))

    if vm.loopStack[^1].eachArray.len == 0 or vm.loopStack[^1].eachIndex >= vm.loopStack[^1].eachArray.len:
      discard vm.loopStack.pop()
      popScope(vm)
      vm.ip = instr.jumpTarget
    else:
      setVar(vm, vm.loopStack[^1].eachItemVar, vm.loopStack[^1].eachArray[vm.loopStack[^1].eachIndex])
      vm.ip.inc

  of inkEndEach:
    vm.iterationCount.inc
    if vm.maxIterations > 0 and vm.iterationCount > vm.maxIterations:
      vm.error = "max iterations exceeded"
      return
    vm.loopStack[^1].eachIndex.inc
    if vm.loopStack[^1].eachIndex < vm.loopStack[^1].eachArray.len:
      setVar(vm, vm.loopStack[^1].eachItemVar, vm.loopStack[^1].eachArray[vm.loopStack[^1].eachIndex])
      vm.ip = instr.jumpTarget
    else:
      discard vm.loopStack.pop()
      popScope(vm)
      vm.ip.inc

  of inkCallBlock:
    if instr.blockName notin vm.blockIndex:
      vm.error = "unknown block '" & instr.blockName & "'"
      return
    if vm.maxCallDepth > 0 and vm.callStack.len >= vm.maxCallDepth:
      vm.error = "max call depth exceeded"
      return
    let targetList = vm.blockIndex[instr.blockName]
    vm.callStack.add((vm.currentList, vm.ip + 1, vm.scope))
    pushScope(vm)
    vm.currentList = targetList
    vm.ip = 0

  of inkReturn:
    if vm.callStack.len == 0:
      vm.halted = true
      return
    popScope(vm)
    let (prevList, prevIp, prevScope) = vm.callStack.pop()
    vm.scope = prevScope
    vm.currentList = prevList
    vm.ip = prevIp

  of inkBreak:
    let header = getLoopHeader(vm)
    let ls = vm.loopStack[^1]
    while vm.scope != ls.loopScope:
      popScope(vm)
    discard vm.loopStack.pop()
    popScope(vm)
    vm.ip = header.jumpTarget
    vm.currentList = ls.innerLoopList

  of inkContinue:
    let header = getLoopHeader(vm)
    let ls = vm.loopStack[^1]
    while vm.scope != ls.loopScope:
      popScope(vm)
    vm.ip = header.loopEndIp

  of inkScopePush:
    pushScope(vm)
    vm.ip.inc

  of inkScopePop:
    popScope(vm)
    vm.ip.inc

  of inkPropRead:
    if instr.peripheral notin vm.peripherals:
      vm.error = "unknown peripheral '" & instr.peripheral & "'"
      return
    if instr.methodName notin vm.peripherals[instr.peripheral].properties:
      vm.error = "unknown property '" & instr.methodName & "' on peripheral '" & instr.peripheral & "'"
      return
    let result = vm.peripherals[instr.peripheral].properties[instr.methodName].getter(vm)
    writeDest(vm, instr, result)
    vm.ip.inc

proc tick*(vm: var VM): bool =
  if vm.halted:
    return false

  vm.tickCount.inc
  if vm.maxTicks > 0 and vm.tickCount > vm.maxTicks:
    vm.error = "max ticks exceeded"
    vm.halted = true
    return false

  executeTick(vm)

  if vm.error != "":
    vm.halted = true

  return not vm.halted

proc run*(vm: var VM): bool =
  while not vm.halted:
    if not tick(vm):
      break

proc getOutput*(vm: VM): string =
  vm.outputBuffer

proc getError*(vm: VM): string =
  if vm.error == "": "" else: vm.error & " (line " & $vm.errorLine & ", col " & $vm.errorCol & ")"

proc valueToJson(v: Value): JsonNode =
  case v.kind
  of vkInt:
    %* {"type": "int", "val": v.intVal}
  of vkFloat:
    %* {"type": "float", "val": v.floatVal}
  of vkStr:
    %* {"type": "str", "val": v.strVal}
  of vkArr:
    var elems = newJArray()
    for e in v.arrVal:
      elems.add(valueToJson(e))
    %* {"type": "arr", "val": elems}
  of vkErr:
    %* {"type": "err", "val": v.errMsg}

proc valueFromJson(node: JsonNode): Value =
  case node["type"].getStr()
  of "int":
    newInt(node["val"].getBiggestInt())
  of "float":
    newFloat(node["val"].getFloat())
  of "str":
    newStr(node["val"].getStr())
  of "arr":
    var elems: seq[Value]
    for e in node["val"]:
      elems.add(valueFromJson(e))
    newArr(elems)
  of "err":
    newErr(node["val"].getStr())
  else:
    newErr("unknown type in serialized data")

proc scopeToJson(frame: ScopeFrame): JsonNode =
  var arr = newJArray()
  for name, val in frame.vars:
    arr.add(%* {"name": name, "value": valueToJson(val)})
  return arr

proc saveState*(vm: VM): string =
  var root = newJObject()
  root["ip"] = %vm.ip
  root["currentList"] = %vm.currentList
  root["halted"] = %vm.halted
  root["error"] = %vm.error
  root["outputBuffer"] = %vm.outputBuffer
  root["tickCount"] = %vm.tickCount
  root["iterationCount"] = %vm.iterationCount

  var scopes = newJArray()
  var frame = vm.scope
  while frame != nil:
    scopes.add(scopeToJson(frame))
    frame = frame.parent
  root["scope"] = scopes

  var cstack = newJArray()
  for (list, ip, frame) in vm.callStack:
    cstack.add(%* {"list": list, "ip": ip, "scope": scopeToJson(frame)})
  root["callStack"] = cstack

  var lstack = newJArray()
  for ls in vm.loopStack:
    var eachArr = newJArray()
    for e in ls.eachArray:
      eachArr.add(valueToJson(e))
    lstack.add(%* {
      "loopCounter": ls.loopCounter,
      "loopTarget": ls.loopTarget,
      "eachIndex": ls.eachIndex,
      "eachItemVar": ls.eachItemVar,
      "eachArray": eachArr,
    })
  root["loopStack"] = lstack

  return $root

proc loadState*(vm: var VM, json: string): bool =
  try:
    let root = parseJson(json)
    vm.ip = root["ip"].getInt()
    vm.currentList = root["currentList"].getInt()
    vm.halted = root["halted"].getBool()
    vm.error = root["error"].getStr()
    vm.outputBuffer = root["outputBuffer"].getStr()
    vm.tickCount = root["tickCount"].getInt()
    vm.iterationCount = root["iterationCount"].getInt()

    # rebuild scope chain from innermost to outermost
    vm.scope = nil
    let scopeNodes = root["scope"]
    for i in countdown(scopeNodes.len - 1, 0):
      var newFrame = ScopeFrame(vars: initTable[string, Value](), parent: vm.scope)
      vm.scope = newFrame
      # load variables into this frame
      for item in scopeNodes[i]:
        let name = item["name"].getStr()
        let val = valueFromJson(item["value"])
        newFrame.vars[name] = val

    vm.callStack = @[]
    for cs in root["callStack"]:
      var frame = ScopeFrame(vars: initTable[string, Value](), parent: nil)
      vm.scope = frame
      for item in cs["scope"]:
        let name = item["name"].getStr()
        let val = valueFromJson(item["value"])
        frame.vars[name] = val
      vm.callStack.add((cs["list"].getInt(), cs["ip"].getInt(), frame))

    # scope was clobbered by callStack rebuilding, restore from root["scope"]
    vm.scope = nil
    for i in countdown(scopeNodes.len - 1, 0):
      var newFrame = ScopeFrame(vars: initTable[string, Value](), parent: vm.scope)
      vm.scope = newFrame
      for item in scopeNodes[i]:
        let name = item["name"].getStr()
        let val = valueFromJson(item["value"])
        newFrame.vars[name] = val

    vm.loopStack = @[]
    for ls in root["loopStack"]:
      var eachArr: seq[Value]
      for e in ls["eachArray"]:
        eachArr.add(valueFromJson(e))
      vm.loopStack.add(LoopState(
        loopScope: nil,
        innerLoopList: -1,
        innerLoopHeaderIp: -1,
        loopCounter: ls["loopCounter"].getBiggestInt(),
        loopTarget: ls["loopTarget"].getBiggestInt(),
        eachIndex: ls["eachIndex"].getInt(),
        eachItemVar: ls["eachItemVar"].getStr(),
        eachArray: eachArr,
      ))

    return true
  except:
    vm.error = "failed to load state: " & getCurrentExceptionMsg()
    return false

proc toF(v: Value): float64 = (if v.kind == vkInt: float64(v.intVal) else: v.floatVal)

proc checkArgs(args: seq[Value], count: int): Value =
  if args.len < count:
    return newErr("requires " & $count & " argument(s)")
  for a in args:
    if a != nil and a.kind == vkErr:
      return a
  nil

proc elemTypeFromVal(v: Value): ArrElemType =
  case v.kind
  of vkInt: aeInt
  of vkFloat: aeFloat
  of vkStr: aeStr
  of vkArr: aeArr
  of vkErr: aeErr

proc registerPeripheral*(vm: var VM, name: string, p: Peripheral) =
  if name == "str" or name == "arr":
    vm.error = "cannot register peripheral with reserved name '" & name & "'"
    vm.halted = true
    return
  vm.peripherals[name] = p

proc newVM*(program: CompiledProgram): VM =
  result.allInstructions = @[program.instructions]
  result.blockIndex = initTable[string, int]()
  for i, (name, instrs) in program.blocks:
    result.blockIndex[name] = result.allInstructions.len
    result.allInstructions.add(instrs)
  result.scope = ScopeFrame(vars: initTable[string, Value]())
  result.callStack = @[]
  result.loopStack = @[]
  result.builtins = initTable[string, BuiltinFn]()
  result.peripherals = initTable[string, Peripheral]()

  {.push overflowChecks: off.}

  result.builtins["set"] = proc(vm: var VM, args: seq[Value]): Value =
    if args.len < 1: return newErr("set requires 1 argument")
    if args[0].kind == vkArr:
      return clone(args[0])
    return args[0]

  result.builtins["log"] = proc(vm: var VM, args: seq[Value]): Value =
    if args.len < 1: return newErr("log requires 1 argument")
    let v = args[0]
    let s = if v == nil: "nil" else: tostrVal(v)
    vm.outputBuffer.add(s)
    return newStr(s)

  result.builtins["halt"] = proc(vm: var VM, args: seq[Value]): Value =
    vm.halted = true
    return newInt(0)

  template arith2(name: string, floatOp, intOp: untyped) =
    result.builtins[name] = proc(vm: var VM, args: seq[Value]): Value =
      let e = checkArgs(args, 2)
      if e != nil: return e
      let a = args[0]; let b = args[1]
      if a.kind notin {vkInt, vkFloat} or b.kind notin {vkInt, vkFloat}:
        return newErr(name & ": requires int or float arguments")
      if a.kind == vkInt and b.kind == vkInt:
        return newInt(intOp(a.intVal, b.intVal))
      else:
        return newFloat(floatOp(toF(a), toF(b)))

  arith2("add", `+`, `+`)
  arith2("sub", `-`, `-`)
  arith2("mul", `*`, `*`)

  result.builtins["div"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind == vkInt and b.kind == vkInt:
      if b.intVal == 0: return newErr("division by zero")
      return newInt(a.intVal div b.intVal)
    elif a.kind in {vkInt, vkFloat} and b.kind in {vkInt, vkFloat}:
      if toF(b) == 0.0: return newErr("division by zero")
      return newFloat(toF(a) / toF(b))
    else: return newErr("div: invalid argument types")

  result.builtins["mod"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind == vkFloat or b.kind == vkFloat:
      return newErr("mod: float operand not allowed")
    if a.kind != vkInt or b.kind != vkInt:
      return newErr("mod: requires int arguments")
    if b.intVal == 0: return newErr("modulo by zero")
    return newInt(a.intVal mod b.intVal)

  result.builtins["pow"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind notin {vkInt, vkFloat} or b.kind notin {vkInt, vkFloat}:
      return newErr("pow: requires int or float arguments")
    if a.kind == vkInt and b.kind == vkInt:
      if b.intVal < 0:
        return newFloat(pow(float64(a.intVal), float64(b.intVal)))
      var r = 1'i64; var exp = b.intVal; var base = a.intVal
      while exp > 0:
        if (exp and 1) == 1: r = r * base
        base = base * base; exp = exp shr 1
      return newInt(r)
    return newFloat(pow(toF(a), toF(b)))

  result.builtins["sqrt"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    let a = args[0]
    if a.kind notin {vkInt, vkFloat}:
      return newErr("sqrt: requires int or float argument")
    if a.kind == vkInt:
      if a.intVal < 0: return newErr("sqrt: negative argument")
      return newInt(int64(sqrt(float64(a.intVal))))
    if a.floatVal < 0.0: return newErr("sqrt: negative argument")
    return newFloat(sqrt(a.floatVal))

  result.builtins["abs"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    let a = args[0]
    if a.kind == vkInt: return newInt(abs(a.intVal))
    if a.kind == vkFloat: return newFloat(abs(a.floatVal))
    return newErr("abs: requires int or float argument")

  result.builtins["min"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind notin {vkInt, vkFloat} or b.kind notin {vkInt, vkFloat}:
      return newErr("min: requires int or float arguments")
    if a.kind == vkInt and b.kind == vkInt:
      return newInt(min(a.intVal, b.intVal))
    return newFloat(min(toF(a), toF(b)))

  result.builtins["max"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind notin {vkInt, vkFloat} or b.kind notin {vkInt, vkFloat}:
      return newErr("max: requires int or float arguments")
    if a.kind == vkInt and b.kind == vkInt:
      return newInt(max(a.intVal, b.intVal))
    return newFloat(max(toF(a), toF(b)))

  result.builtins["rng"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind != vkInt or b.kind != vkInt:
      return newErr("rng: requires int arguments")
    if a.intVal > b.intVal: return newErr("rng: min > max")
    return newInt(rand(a.intVal .. b.intVal))

  result.builtins["and"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind != vkInt or b.kind != vkInt:
      return newErr("and: requires int arguments")
    return newInt(a.intVal and b.intVal)

  result.builtins["or"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind != vkInt or b.kind != vkInt:
      return newErr("or: requires int arguments")
    return newInt(a.intVal or b.intVal)

  result.builtins["xor"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind != vkInt or b.kind != vkInt:
      return newErr("xor: requires int arguments")
    return newInt(a.intVal xor b.intVal)

  result.builtins["not"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    if args[0].kind != vkInt: return newErr("not: requires int argument")
    return newInt(not args[0].intVal)

  result.builtins["shl"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind != vkInt or b.kind != vkInt:
      return newErr("shl: requires int arguments")
    return newInt(a.intVal shl b.intVal.int)

  result.builtins["shr"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    let a = args[0]; let b = args[1]
    if a.kind != vkInt or b.kind != vkInt:
      return newErr("shr: requires int arguments")
    return newInt(a.intVal shr b.intVal.int)

  result.builtins["typeof"] = proc(vm: var VM, args: seq[Value]): Value =
    if args.len < 1: return newErr("typeof requires 1 argument")
    let v = args[0]
    if v == nil: return newStr("nil")
    return newStr(typeName(v))

  result.builtins["tostr"] = proc(vm: var VM, args: seq[Value]): Value =
    if args.len < 1: return newErr("tostr requires 1 argument")
    return newStr(tostrVal(args[0]))

  result.builtins["toint"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    let v = args[0]
    if v.kind == vkInt:
      return newInt(v.intVal)
    elif v.kind == vkFloat:
      return newInt(int64(v.floatVal))
    elif v.kind == vkStr:
      try:
        return newInt(parseBiggestInt(v.strVal))
      except ValueError:
        return newErr("toint: invalid integer string")
    else:
      return newErr("toint: cannot convert type")

  result.builtins["tofloat"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    let v = args[0]
    if v.kind == vkInt:
      return newFloat(float64(v.intVal))
    elif v.kind == vkFloat:
      return newFloat(v.floatVal)
    elif v.kind == vkStr:
      try:
        if '.' notin v.strVal:
          return newFloat(parseFloat(v.strVal))
        return newFloat(parseFloat(v.strVal))
      except ValueError:
        return newErr("tofloat: invalid float string")
    else:
      return newErr("tofloat: cannot convert type")

  result.builtins["str.len"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    if args[0].kind != vkStr: return newErr("str.len: requires string argument")
    return newInt(int64(args[0].strVal.runeLen))

  result.builtins["str.get"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    if args[0].kind != vkStr: return newErr("str.get: requires string argument")
    if args[1].kind != vkInt: return newErr("str.get: index must be int")
    let s = args[0].strVal
    let idx = args[1].intVal
    if idx < 0 or idx >= s.runeLen:
      return newErr("str.get: index out of bounds")
    let bytePos = s.runeOffset(int(idx))
    return newStr($s.runeAt(bytePos))

  result.builtins["str.cat"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    if args[0].kind != vkStr or args[1].kind != vkStr:
      return newErr("str.cat: requires string arguments")
    return newStr(args[0].strVal & args[1].strVal)

  result.builtins["str.slice"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 3)
    if e != nil: return e
    if args[0].kind != vkStr: return newErr("str.slice: requires string argument")
    if args[1].kind != vkInt or args[2].kind != vkInt:
      return newErr("str.slice: indices must be int")
    let s = args[0].strVal
    let rl = s.runeLen
    var start = int(args[1].intVal)
    var endPos = int(args[2].intVal)
    if start < 0: start = 0
    if start > rl: start = rl
    if endPos < start: endPos = start
    if endPos > rl: endPos = rl
    if start >= endPos: return newStr("")
    let byteStart = s.runeOffset(start)
    let byteEnd = if endPos >= rl: s.len else: s.runeOffset(endPos)
    return newStr(s[byteStart ..< byteEnd])

  result.builtins["str.find"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    if args[0].kind != vkStr or args[1].kind != vkStr:
      return newErr("str.find: requires string arguments")
    let s = args[0].strVal
    let needle = args[1].strVal
    let bytePos = s.find(needle)
    if bytePos == -1: return newInt(-1)
    return newInt(int64(runeLen(s[0 ..< bytePos])))

  result.builtins["str.upper"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    if args[0].kind != vkStr: return newErr("str.upper: requires string argument")
    return newStr(args[0].strVal.toUpper)

  result.builtins["str.lower"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    if args[0].kind != vkStr: return newErr("str.lower: requires string argument")
    return newStr(args[0].strVal.toLower)

  result.builtins["str.split"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    if args[0].kind != vkStr: return newErr("str.split: requires string argument")
    if args[1].kind != vkStr: return newErr("str.split: separator must be string")
    let s = args[0].strVal
    let sep = args[1].strVal
    if sep == "": return newErr("str.split: empty separator")
    let parts = s.split(sep)
    var elems: seq[Value]
    for p in parts:
      elems.add(newStr(p))
    return newArr(elems)

  result.builtins["str.trim"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    if args[0].kind != vkStr: return newErr("str.trim: requires string argument")
    return newStr(args[0].strVal.strip)

  result.builtins["str.join"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    if args[0].kind != vkArr: return newErr("str.join: requires array argument")
    if args[1].kind != vkStr: return newErr("str.join: separator must be string")
    if args[0].elemType != aeStr and args[0].arrVal.len > 0:
      return newErr("str.join: array must contain strings")
    let sep = args[1].strVal
    var parts: seq[string]
    for v in args[0].arrVal:
      if v.kind != vkStr:
        return newErr("str.join: array must contain strings")
      parts.add(v.strVal)
    return newStr(parts.join(sep))

  result.builtins["arr.new"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    if args[0].kind != vkInt: return newErr("arr.new: requires int argument")
    return newArr()

  result.builtins["arr.len"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    if args[0].kind != vkArr: return newErr("arr.len: requires array argument")
    return newInt(int64(args[0].arrVal.len))

  result.builtins["arr.get"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    if args[0].kind != vkArr: return newErr("arr.get: requires array argument")
    if args[1].kind != vkInt: return newErr("arr.get: index must be int")
    let idx = args[1].intVal
    if idx < 0 or idx >= args[0].arrVal.len:
      return newErr("arr.get: index out of bounds")
    return args[0].arrVal[idx]

  result.builtins["arr.set"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 3)
    if e != nil: return e
    if args[0].kind != vkArr: return newErr("arr.set: requires array argument")
    if args[1].kind != vkInt: return newErr("arr.set: index must be int")
    let idx = args[1].intVal
    if idx < 0 or idx >= args[0].arrVal.len:
      return newErr("arr.set: index out of bounds")
    args[0].arrVal[idx] = args[2]
    return args[2]

  result.builtins["arr.push"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    if args[0].kind != vkArr: return newErr("arr.push: requires array argument")
    let elemType = elemTypeFromVal(args[1])
    if args[0].arrVal.len > 0:
      if args[0].elemType != elemType:
        return newErr("arr.push: type mismatch")
    else:
      args[0].elemType = elemType
    args[0].arrVal.add(args[1])
    return newInt(int64(args[0].arrVal.len))

  result.builtins["arr.pop"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    if args[0].kind != vkArr: return newErr("arr.pop: requires array argument")
    if args[0].arrVal.len == 0: return newErr("arr.pop: empty array")
    let val = args[0].arrVal.pop()
    if args[0].arrVal.len == 0:
      args[0].elemType = aeUnset
    return val

  result.builtins["arr.sort"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 1)
    if e != nil: return e
    if args[0].kind != vkArr: return newErr("arr.sort: requires array argument")
    proc cmpVals(a, b: Value): int =
      if a.kind == vkInt and b.kind == vkInt:
        return cmp(a.intVal, b.intVal)
      elif a.kind == vkFloat and b.kind == vkFloat:
        return cmp(a.floatVal, b.floatVal)
      elif a.kind == vkInt and b.kind == vkFloat:
        return cmp(float64(a.intVal), b.floatVal)
      elif a.kind == vkFloat and b.kind == vkInt:
        return cmp(a.floatVal, float64(b.intVal))
      elif a.kind == vkStr and b.kind == vkStr:
        return cmp(a.strVal, b.strVal)
      else:
        return 0
    args[0].arrVal.sort(cmpVals)
    return args[0]

  result.builtins["arr.contains"] = proc(vm: var VM, args: seq[Value]): Value =
    let e = checkArgs(args, 2)
    if e != nil: return e
    if args[0].kind != vkArr: return newErr("arr.contains: requires array argument")
    let targetType = elemTypeFromVal(args[1])
    if args[0].arrVal.len > 0 and args[0].elemType != targetType:
      return newInt(0)
    for v in args[0].arrVal:
      if cmpEq(v, args[1]):
        return newInt(1)
    return newInt(0)

  {.pop.}
