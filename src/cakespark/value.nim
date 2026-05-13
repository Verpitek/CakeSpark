import std/strutils

type
  ValueKind* = enum
    vkInt
    vkFloat
    vkStr
    vkArr
    vkErr

  ArrElemType* = enum
    aeUnset
    aeInt
    aeFloat
    aeStr
    aeArr
    aeErr

  ValueObj* = object
    case kind*: ValueKind
    of vkInt:
      intVal*: int64
    of vkFloat:
      floatVal*: float64
    of vkStr:
      strVal*: string
    of vkArr:
      arrVal*: seq[Value]
      elemType*: ArrElemType
    of vkErr:
      errMsg*: string

  Value* = ref ValueObj

proc newInt*(v: int64): Value =
  Value(kind: vkInt, intVal: v)

proc newFloat*(v: float64): Value =
  Value(kind: vkFloat, floatVal: v)

proc newStr*(v: string): Value =
  Value(kind: vkStr, strVal: v)

proc newArr*(elems: seq[Value] = @[]): Value =
  result = Value(kind: vkArr, arrVal: elems, elemType: aeUnset)
  if elems.len > 0:
    case elems[0].kind
    of vkInt: result.elemType = aeInt
    of vkFloat: result.elemType = aeFloat
    of vkStr: result.elemType = aeStr
    of vkArr: result.elemType = aeArr
    of vkErr: result.elemType = aeErr

proc newErr*(msg: string): Value =
  Value(kind: vkErr, errMsg: msg)

proc clone*(v: Value): Value =
  case v.kind
  of vkInt:
    result = Value(kind: vkInt, intVal: v.intVal)
  of vkFloat:
    result = Value(kind: vkFloat, floatVal: v.floatVal)
  of vkStr:
    result = Value(kind: vkStr, strVal: v.strVal)
  of vkArr:
    result = Value(kind: vkArr, elemType: v.elemType)
    result.arrVal = newSeq[Value](v.arrVal.len)
    for i, e in v.arrVal:
      result.arrVal[i] = clone(e)
  of vkErr:
    result = Value(kind: vkErr, errMsg: v.errMsg)

proc `$`*(v: Value): string =
  case v.kind
  of vkInt: $v.intVal
  of vkFloat: $v.floatVal
  of vkStr: "\"" & v.strVal & "\""
  of vkArr:
    var parts: seq[string]
    for e in v.arrVal:
      parts.add($e)
    "[" & parts.join(", ") & "]"
  of vkErr: "err(" & v.errMsg & ")"

proc typeName*(v: Value): string =
  case v.kind
  of vkInt: "int"
  of vkFloat: "float"
  of vkStr: "str"
  of vkArr: "arr"
  of vkErr: "err"
