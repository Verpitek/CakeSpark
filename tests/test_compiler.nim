import unittest
import strutils
import cakespark/lexer
import cakespark/parser
import cakespark/compiler

proc compileSource(source: string): CompiledProgram =
  let tokens = tokenize(source)
  var parser = newParser(tokens)
  let program = parser.parse()
  compile(program)

suite "compiler - function calls":

  test "bare funcall with literal args":
    let prog = compileSource("add 1 2\n")
    check prog.instructions.len == 1
    check prog.instructions[0].kind == inkCall
    check prog.instructions[0].funcName == "add"
    check prog.instructions[0].isMethod == false
    check prog.instructions[0].args.len == 2
    check prog.instructions[0].args[0].kind == rakInt
    check prog.instructions[0].args[0].intVal == 1
    check prog.instructions[0].args[1].kind == rakInt
    check prog.instructions[0].args[1].intVal == 2

  test "funcall with pipe":
    let prog = compileSource("set 10 >> x\n")
    check prog.instructions.len == 1
    let instr = prog.instructions[0]
    check instr.kind == inkCall
    check instr.funcName == "set"
    check instr.hasDest == true
    check instr.destVar == "x"

  test "method call":
    let prog = compileSource("player.heal(50)\n")
    check prog.instructions.len == 1
    let instr = prog.instructions[0]
    check instr.kind == inkCall
    check instr.isMethod == true
    check instr.peripheral == "player"
    check instr.methodName == "heal"
    check instr.args.len == 1

  test "method with pipe":
    let prog = compileSource("player.getHealth() >> hp\n")
    let instr = prog.instructions[0]
    check instr.hasDest == true
    check instr.destVar == "hp"

  test "multiple statements":
    let prog = compileSource("set 1 >> x\nadd x 2 >> y\n")
    check prog.instructions.len == 2
    check prog.instructions[0].funcName == "set"
    check prog.instructions[1].funcName == "add"


suite "compiler - if / elif / else":

  test "simple if":
    let prog = compileSource("if x < 10\n  set 1 >> y\nend\n")
    check prog.instructions.len == 5
    check prog.instructions[0].kind == inkIf
    check prog.instructions[0].condition.left.identName == "x"
    check prog.instructions[0].condition.op == tkLt
    check prog.instructions[1].kind == inkScopePush
    check prog.instructions[2].kind == inkCall
    check prog.instructions[3].kind == inkScopePop
    check prog.instructions[4].kind == inkEnd

  test "if with else":
    let prog = compileSource("if x == 0\n  set 1 >> y\nelse\n  set 2 >> y\nend\n")
    check prog.instructions[0].kind == inkIf
    check prog.instructions[0].jumpTarget > 0
    check prog.instructions[^1].kind == inkEnd

  test "if elif else":
    let prog = compileSource("if x > 80\n  set 1 >> a\nelif x > 50\n  set 2 >> a\nelse\n  set 3 >> a\nend\n")
    var kinds: seq[InstrKind] = @[]
    for i in prog.instructions:
      kinds.add(i.kind)
    check kinds.contains(inkIf)
    check kinds.contains(inkElse)
    check kinds.contains(inkEnd)

  test "nested if":
    let prog = compileSource("if x > 0\n  if x > 10\n    set 1 >> y\n  end\nend\n")
    check prog.instructions.len > 0
    var ifCount = 0
    for i in prog.instructions:
      if i.kind == inkIf:
        ifCount.inc
    check ifCount == 2


suite "compiler - while":

  test "simple while":
    let prog = compileSource("while i < 10\n  add i 1 >> i\nend\n")
    check prog.instructions[0].kind == inkWhile
    check prog.instructions[0].jumpTarget > 0
    check prog.instructions[0].loopEndIp > 0
    check prog.instructions[^1].kind == inkEnd


suite "compiler - loop":

  test "loop literal":
    let prog = compileSource("loop 5\n  set 1 >> x\nend\n")
    check prog.instructions[0].kind == inkLoop
    check prog.instructions[0].countVal == 5
    check prog.instructions[0].jumpTarget > 0
    check prog.instructions[0].loopEndIp > 0

  test "loop variable":
    let prog = compileSource("loop n\n  set 1 >> x\nend\n")
    check prog.instructions[0].kind == inkLoop
    check prog.instructions[0].countName == "n"


suite "compiler - each":

  test "each array variable":
    let prog = compileSource("each items >> item\n  log \"{item}\"\nend\n")
    check prog.instructions[0].kind == inkEach
    check prog.instructions[0].arrayName == "items"
    check prog.instructions[0].itemVar == "item"
    check prog.instructions[0].loopEndIp > 0

  test "each array literal":
    let prog = compileSource("each [1, 2, 3] >> n\n  log \"{n}\"\nend\n")
    check prog.instructions[0].kind == inkEach
    check prog.instructions[0].arrayLit.len == 3


suite "compiler - blocks":

  test "block definition":
    let prog = compileSource("block foo\n  set 1 >> x\nend\nrun foo\n")
    var found = false
    for (name, instrs) in prog.blocks:
      if name == "foo":
        found = true
        check instrs.len > 0
    check found

  test "run block":
    let prog = compileSource("block bar\n  set 1 >> x\nend\nrun bar\n")
    check prog.instructions[0].kind == inkCallBlock
    check prog.instructions[0].blockName == "bar"


suite "compiler - break / continue":

  test "break in loop":
    let prog = compileSource("while 1 == 1\n  break\nend\n")
    check prog.instructions.len > 0
    var found = false
    for i in prog.instructions:
      if i.kind == inkBreak:
        found = true
    check found

  test "continue in loop":
    let prog = compileSource("while 1 == 1\n  continue\nend\n")
    check prog.instructions.len > 0
    var found = false
    for i in prog.instructions:
      if i.kind == inkContinue:
        found = true
    check found

  test "break outside loop is error":
    let prog = compileSource("break\n")
    check prog.hasError
    check prog.errorMsg.contains("outside any loop")

  test "continue outside loop is error":
    let prog = compileSource("continue\n")
    check prog.hasError
    check prog.errorMsg.contains("outside any loop")


suite "compiler - empty / positions":

  test "empty program":
    let prog = compileSource("// just a comment\n")
    check prog.instructions.len == 0

  test "source positions preserved":
    let prog = compileSource("set 10 >> x\nadd x 5 >> y\n")
    check prog.instructions[0].line == 1
    check prog.instructions[0].col == 1
    check prog.instructions[1].line == 2
    check prog.instructions[1].col == 1
