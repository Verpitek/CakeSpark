import cakespark/value
import cakespark/lexer
import cakespark/parser
import cakespark/compiler
import cakespark/vm
import cakespark/cakespark

export value
export lexer
export parser
export compiler
export vm

when isMainModule:
  import std/[os, strutils, tables]

  proc isComplete(source: string): bool =
    let tokens = tokenize(source)
    var depth = 0
    for tok in tokens:
      case tok.typ
      of tkKwIf, tkKwWhile, tkKwLoop, tkKwEach, tkKwBlock:
        depth.inc
      of tkKwEnd:
        depth.dec
        if depth < 0:
          depth = 0
      else: discard
    return depth <= 0

  proc runFile(filename: string) =
    if not fileExists(filename):
      stderr.writeLine("Error: file not found: " & filename)
      quit(1)
    let source = readFile(filename)
    let program = compileSource(source)
    if program.hasError:
      stderr.writeLine("Compile error: " & program.errorMsg)
      quit(1)
    var vm = newVM(program)
    discard vm.run()
    let output = vm.getOutput()
    if output.len > 0:
      stdout.write(output)
    let err = vm.getError()
    if err != "":
      stderr.writeLine("Error: " & err)
      quit(1)

  proc repl() =
    echo "CakeSpark 1.0.0 - type .quit or .exit to leave"
    var vm = newVM(compileSource(""))
    var buffer = ""
    var continuation = false
    while true:
      if continuation:
        stdout.write("... ")
      else:
        stdout.write(">>> ")
      stdout.flushFile()
      var line: string
      let ok = readLine(stdin, line)
      if not ok:
        echo ""
        break
      let trimmed = line.strip()
      if trimmed == ".quit" or trimmed == ".exit":
        break
      if trimmed.len == 0 and not continuation:
        continue
      buffer.add(line & "\n")
      if not isComplete(buffer):
        continuation = true
        continue
      continuation = false
      let tokens = tokenize(buffer)
      var parser = newParser(tokens)
      let program = parser.parse()
      if parser.hasError:
        stderr.writeLine("Parse error: " & parser.errorMsg)
        buffer = ""
        continue
      var compiled = compile(program)
      if compiled.hasError:
        stderr.writeLine("Compile error: " & compiled.errorMsg)
        buffer = ""
        continue
      let baseOffset = vm.allInstructions[0].len
      for instr in compiled.instructions.mitems:
        case instr.kind
        of inkIf, inkElse, inkWhile, inkEndWhile, inkEndLoop, inkEndEach:
          instr.jumpTarget += baseOffset
        of inkLoop, inkEach:
          instr.jumpTarget += baseOffset
          instr.loopEndIp += baseOffset
        else: discard
      vm.allInstructions[0].add(compiled.instructions)
      for (name, instrs) in compiled.blocks:
        vm.blockIndex[name] = vm.allInstructions.len
        vm.allInstructions.add(instrs)
      vm.halted = false
      vm.error = ""
      discard vm.run()
      let output = vm.getOutput()
      if output.len > 0:
        stdout.write(output)
        if not output.endsWith("\n"):
          stdout.write("\n")
        vm.outputBuffer = ""
      let err = vm.getError()
      if err != "":
        stderr.writeLine("Error: " & err)
        vm.error = ""
      buffer = ""

  let args = commandLineParams()
  if args.len == 0:
    repl()
  elif args.len == 1:
    runFile(args[0])
  else:
    stderr.writeLine("Usage: cakespark [filename]")
    quit(1)
