import cakespark/cakespark

type
  CakeVMObj = object
    vm: VM
    savedState: string

  CakeVM* = ptr CakeVMObj

  CakeValue* = Value

  CakeLimits* = object
    maxCallDepth*: int32
    maxIterations*: int32
    maxTicks*: int32
    maxVariables*: int32
    maxMemory*: int32

  CakeFn* = proc(vm: CakeVM, argc: int32, argv: ptr CakeValue): CakeValue {.cdecl.}

  CakePeripheralProperty* = object
    getter*: proc(vm: CakeVM): CakeValue {.cdecl.}
    setter*: proc(vm: CakeVM, val: CakeValue) {.cdecl.}
    hasSetter*: bool

  CakePeripheral* = object
    properties*: proc(vm: CakeVM, name: cstring, prop: ptr CakePeripheralProperty): bool {.cdecl.}
    methods*: proc(vm: CakeVM, name: cstring, handler: ptr CakeFn): bool {.cdecl.}

proc cake_version*(): cstring {.exportc, dynlib, cdecl.} =
  return "1.0.0"

proc cake_new*(limits: CakeLimits): CakeVM {.exportc, dynlib, cdecl.} =
  result = cast[CakeVM](alloc0(sizeof(CakeVMObj)))
  result.vm = newVM(compileSource(""))
  when defined(cakesparkDirect):
    result.vm.maxCallDepth = 0
    result.vm.maxIterations = 0
    result.vm.maxTicks = 0
  else:
    result.vm.maxCallDepth = int(limits.maxCallDepth)
    result.vm.maxIterations = int(limits.maxIterations)
    result.vm.maxTicks = int(limits.maxTicks)
    result.vm.maxVariables = int(limits.maxVariables)
    result.vm.maxMemory = int(limits.maxMemory)

proc cake_free*(cv: CakeVM) {.exportc, dynlib, cdecl.} =
  dealloc(cast[pointer](cv))

proc cake_compile*(cv: CakeVM, source: cstring): int32 {.exportc, dynlib, cdecl.} =
  let compiled = compileSource($source)
  cv.vm = newVM(compiled)
  if compiled.hasError:
    cv.vm.error = compiled.errorMsg
    return -1
  return 0

proc cake_tick*(cv: CakeVM): int32 {.exportc, dynlib, cdecl.} =
  if cv.vm.halted:
    return 0
  if not tick(cv.vm):
    if cv.vm.error == "":
      return 0
    else:
      return -1
  return 1

proc cake_run*(cv: CakeVM): int32 {.exportc, dynlib, cdecl.} =
  if run(cv.vm):
    if cv.vm.error != "": return -1
    return 0
  if cv.vm.error != "": return -1
  return 0

proc cake_get_var*(cv: CakeVM, name: cstring): CakeValue {.exportc, dynlib, cdecl.} =
  getVar(cv.vm, $name)

proc cake_set_var*(cv: CakeVM, name: cstring, val: CakeValue) {.exportc, dynlib, cdecl.} =
  setVar(cv.vm, $name, val)

proc cake_get_output*(cv: CakeVM): cstring {.exportc, dynlib, cdecl.} =
  cv.vm.outputBuffer.cstring

proc cake_get_error*(cv: CakeVM): cstring {.exportc, dynlib, cdecl.} =
  cv.vm.error.cstring

proc cake_save_state*(cv: CakeVM): cstring {.exportc, dynlib, cdecl.} =
  cv.savedState = saveState(cv.vm)
  cv.savedState.cstring

proc cake_load_state*(cv: CakeVM, json: cstring): int32 {.exportc, dynlib, cdecl.} =
  if loadState(cv.vm, $json): 0 else: -1
