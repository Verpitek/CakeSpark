import unittest
import strutils
import cakespark/lexer
import cakespark/parser

proc parseSource(source: string): Program =
  let tokens = tokenize(source)
  var parser = newParser(tokens)
  parser.parse()

suite "parser - bare function calls":

  test "no args":
    let prog = parseSource("halt\n")
    check prog.statements.len == 1
    check prog.statements[0].kind == ankFuncall
    check prog.statements[0].funcName == "halt"
    check prog.statements[0].args.len == 0
    check prog.statements[0].hasDest == false

  test "with literal args":
    let prog = parseSource("add 1 2\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankFuncall
    check node.funcName == "add"
    check node.args.len == 2
    check node.args[0].kind == akInt
    check node.args[0].intVal == 1
    check node.args[1].kind == akInt
    check node.args[1].intVal == 2

  test "with pipe to variable":
    let prog = parseSource("set 10 >> x\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankFuncall
    check node.funcName == "set"
    check node.args.len == 1
    check node.args[0].intVal == 10
    check node.hasDest == true
    check node.dest.isProperty == false
    check node.dest.varName == "x"

  test "with string arg containing interpolation":
    let prog = parseSource("log \"hello {name}\"\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankFuncall
    check node.funcName == "log"
    check node.args.len == 1
    check node.args[0].kind == akString
    check node.args[0].strParts.len == 2
    check node.args[0].strParts[0].isInterp == false
    check node.args[0].strParts[0].lit == "hello "
    check node.args[0].strParts[1].isInterp == true
    check node.args[0].strParts[1].varName == "name"

  test "with true and false":
    let prog = parseSource("set true >> flag\nset false >> stop\n")
    check prog.statements.len == 2
    check prog.statements[0].args[0].kind == akTrue
    check prog.statements[1].args[0].kind == akFalse


suite "parser - method calls":

  test "zero args":
    let prog = parseSource("player.getHealth()\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankMethodCall
    check node.peripheral == "player"
    check node.methodName == "getHealth"
    check node.args.len == 0
    check node.hasDest == false

  test "one arg":
    let prog = parseSource("player.heal(50)\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankMethodCall
    check node.peripheral == "player"
    check node.methodName == "heal"
    check node.args.len == 1
    check node.args[0].kind == akInt
    check node.args[0].intVal == 50

  test "multiple args":
    let prog = parseSource("player.moveTo(10, 20)\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankMethodCall
    check node.peripheral == "player"
    check node.methodName == "moveTo"
    check node.args.len == 2
    check node.args[0].intVal == 10
    check node.args[1].intVal == 20

  test "method with pipe":
    let prog = parseSource("player.getHealth() >> hp\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankMethodCall
    check node.methodName == "getHealth"
    check node.hasDest == true
    check node.dest.varName == "hp"


suite "parser - if / elif / else":

  test "simple if":
    let prog = parseSource("if x < 10\n  log \"yes\"\nend\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankIf
    check node.branches.len == 1
    check node.branches[0].hasCondition == true
    check node.branches[0].condition.left.kind == akIdent
    check node.branches[0].condition.left.identName == "x"
    check node.branches[0].condition.op == tkLt
    check node.branches[0].condition.right.kind == akInt
    check node.branches[0].condition.right.intVal == 10
    check node.branches[0].body.len == 1

  test "if with else":
    let prog = parseSource("if x == 0\n  log \"zero\"\nelse\n  log \"not zero\"\nend\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankIf
    check node.branches.len == 2
    check node.branches[0].hasCondition == true
    check node.branches[1].hasCondition == false
    check node.branches[0].body.len == 1
    check node.branches[1].body.len == 1

  test "if elif else":
    let prog = parseSource("if x > 80\n  log \"great\"\nelif x > 50\n  log \"ok\"\nelse\n  log \"bad\"\nend\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankIf
    check node.branches.len == 3
    check node.branches[0].hasCondition == true
    check node.branches[1].hasCondition == true
    check node.branches[2].hasCondition == false

  test "nested if":
    let prog = parseSource("if x > 0\n  if x > 10\n    log \"big\"\n  end\nend\n")
    check prog.statements.len == 1
    let outer = prog.statements[0]
    check outer.kind == ankIf
    check outer.branches.len == 1
    check outer.branches[0].body.len == 1
    check outer.branches[0].body[0].kind == ankIf

  test "empty body error":
    var tokens = tokenize("if x < 10\nend")
    var parser = newParser(tokens)
    discard parser.parse()
    check parser.hasError
    check parser.errorMsg.contains("empty body")


suite "parser - while":

  test "simple while":
    let prog = parseSource("while i < 10\n  log \"{i}\"\n  add i 1 >> i\nend\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankWhile
    check node.condition.left.identName == "i"
    check node.condition.op == tkLt
    check node.condition.right.intVal == 10
    check node.body.len == 2

  test "empty body error":
    var tokens = tokenize("while x < 10\nend")
    var parser = newParser(tokens)
    discard parser.parse()
    check parser.hasError
    check parser.errorMsg.contains("empty body")


suite "parser - loop":

  test "literal count":
    let prog = parseSource("loop 5\n  player.step()\nend\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankLoop
    check node.count.kind == akInt
    check node.count.intVal == 5
    check node.body.len == 1

  test "empty body error":
    var tokens = tokenize("loop 5\nend")
    var parser = newParser(tokens)
    discard parser.parse()
    check parser.hasError
    check parser.errorMsg.contains("empty body")


suite "parser - each":

  test "array iteration":
    let prog = parseSource("each items >> item\n  log \"{item}\"\nend\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankEach
    check node.collection.kind == akIdent
    check node.collection.identName == "items"
    check node.itemVar == "item"
    check node.body.len == 1

  test "empty body error":
    var tokens = tokenize("each arr >> x\nend")
    var parser = newParser(tokens)
    discard parser.parse()
    check parser.hasError
    check parser.errorMsg.contains("empty body")


suite "parser - break / continue":

  test "break":
    let prog = parseSource("break\n")
    check prog.statements.len == 1
    check prog.statements[0].kind == ankBreak

  test "continue":
    let prog = parseSource("continue\n")
    check prog.statements.len == 1
    check prog.statements[0].kind == ankContinue


suite "parser - block definitions":

  test "simple block":
    let prog = parseSource("block foo\n  log \"hi\"\nend\n")
    check prog.blockDefs.len == 1
    check prog.statements.len == 0
    let node = prog.blockDefs[0]
    check node.kind == ankBlockDef
    check node.blockName == "foo"
    check node.body.len == 1

  test "block with multiple statements":
    let prog = parseSource("block patrol\n  player.moveTo(0, 0)\n  player.wait(5)\nend\n")
    check prog.blockDefs.len == 1
    let node = prog.blockDefs[0]
    check node.blockName == "patrol"
    check node.body.len == 2

  test "empty body error":
    var tokens = tokenize("block foo\nend")
    var parser = newParser(tokens)
    discard parser.parse()
    check parser.hasError
    check parser.errorMsg.contains("empty body")


suite "parser - run statements":

  test "simple run":
    let prog = parseSource("run foo\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankRun
    check node.blockName == "foo"

  test "run in if body":
    let prog = parseSource("if x > 0\n  run patrol\nend\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankIf
    check node.branches[0].body[0].kind == ankRun
    check node.branches[0].body[0].blockName == "patrol"


suite "parser - array literals":

  test "int array":
    let prog = parseSource("set [1, 2, 3] >> nums\n")
    let node = prog.statements[0]
    let arr = node.args[0]
    check arr.kind == akArray
    check arr.arrayElems.len == 3
    check arr.arrayElems[0].intVal == 1
    check arr.arrayElems[1].intVal == 2
    check arr.arrayElems[2].intVal == 3

  test "empty array":
    let prog = parseSource("set [] >> empty\n")
    let node = prog.statements[0]
    let arr = node.args[0]
    check arr.kind == akArray
    check arr.arrayElems.len == 0

  test "string array":
    let prog = parseSource("set [\"a\", \"b\"] >> letters\n")
    let node = prog.statements[0]
    let arr = node.args[0]
    check arr.kind == akArray
    check arr.arrayElems.len == 2
    check arr.arrayElems[0].kind == akString
    check arr.arrayElems[0].strParts[0].lit == "a"
    check arr.arrayElems[1].kind == akString
    check arr.arrayElems[1].strParts[0].lit == "b"


suite "parser - comments and blank lines":

  test "comment-only script produces empty program":
    let prog = parseSource("// just a comment\n")
    check prog.statements.len == 0
    check prog.blockDefs.len == 0

  test "blank lines between statements":
    let prog = parseSource("set 1 >> x\n\n\nadd x 1 >> y\n")
    check prog.statements.len == 2
    check prog.statements[0].funcName == "set"
    check prog.statements[1].funcName == "add"


suite "parser - full programs":

  test "multi-line script with mixed constructs":
    let source = "set 10 >> x\n" &
                 "add x 5 >> result\n" &
                 "log \"the answer is {result}\"\n"
    let prog = parseSource(source)
    check prog.statements.len == 3
    check prog.statements[0].kind == ankFuncall
    check prog.statements[0].funcName == "set"
    check prog.statements[1].kind == ankFuncall
    check prog.statements[1].funcName == "add"
    check prog.statements[2].kind == ankFuncall
    check prog.statements[2].funcName == "log"

  test "script with block definition and run":
    let source = "block increment\n  add counter 1 >> counter\nend\n" &
                 "set 0 >> counter\n" &
                 "run increment\n" &
                 "log \"{counter}\"\n"
    let prog = parseSource(source)
    check prog.blockDefs.len == 1
    check prog.blockDefs[0].blockName == "increment"
    check prog.statements.len == 3
    check prog.statements[0].funcName == "set"
    check prog.statements[1].kind == ankRun
    check prog.statements[1].blockName == "increment"
    check prog.statements[2].funcName == "log"

  test "node positions are preserved":
    let prog = parseSource("set 10 >> x\nadd x 5 >> y\n")
    check prog.statements[0].line == 1
    check prog.statements[0].col == 1
    check prog.statements[1].line == 2
    check prog.statements[1].col == 1

  test "pipe to peripheral property":
    let prog = parseSource("player.getHealth() >> player.health\n")
    check prog.statements.len == 1
    let node = prog.statements[0]
    check node.kind == ankMethodCall
    check node.hasDest == true
    check node.dest.isProperty == true
    check node.dest.peripheral == "player"
    check node.dest.property == "health"

  test "method call without parens is error":
    var tokens = tokenize("player.health\n")
    var parser = newParser(tokens)
    let prog = parser.parse()
    check not parser.hasError
    check prog.statements.len == 1
    check prog.statements[0].kind == ankPropRead

  test "parse error does not crash on lone dot":
    var tokens = tokenize("set 10 >> x.\n")
    var parser = newParser(tokens)
    discard parser.parse()
    check parser.hasError
