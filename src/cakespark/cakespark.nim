import cakespark/value
import cakespark/lexer
import cakespark/parser
import cakespark/compiler
import cakespark/vm

export Value, ValueKind, ValueObj
export newInt, newFloat, newStr, newArr, newErr, clone, typeName
export Lexer, Token, TokenType, StringPart, tokenize, newLexer
export Parser, Program, AstNode, AstNodeKind, Destination, Condition, newParser, parse
export Compiler, Instruction, InstrKind, CompiledProgram, compile
export VM, ScopeFrame, ScopeFrameObj, BuiltinFn, LoopState
export Peripheral, PeripheralProperty, PropertyGetter, PropertySetter, MethodHandler
export newVM, tick, run, getVar, setVar, registerPeripheral, saveState, loadState, getOutput, getError

proc compileSource*(source: string): CompiledProgram =
  let tokens = tokenize(source)
  var parser = newParser(tokens)
  let program = parser.parse()
  compile(program)
