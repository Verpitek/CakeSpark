import unittest
import strutils
import cakespark/value
import cakespark/lexer

suite "lexer - identifiers and keywords":

  test "plain identifier":
    let tokens = tokenize("health")
    check tokens.len == 2
    check tokens[0].typ == tkIdent
    check tokens[0].lexeme == "health"
    check tokens[1].typ == tkEof

  test "identifier with underscores and digits":
    let tokens = tokenize("player_hp")
    check tokens[0].typ == tkIdent
    check tokens[0].lexeme == "player_hp"

    let tokens2 = tokenize("x1")
    check tokens2[0].typ == tkIdent
    check tokens2[0].lexeme == "x1"

    let tokens3 = tokenize("_temp")
    check tokens3[0].typ == tkIdent
    check tokens3[0].lexeme == "_temp"

  test "all 14 keywords":
    let kwTests = [
      ("set", tkKwSet),
      ("if", tkKwIf),
      ("elif", tkKwElif),
      ("else", tkKwElse),
      ("end", tkKwEnd),
      ("while", tkKwWhile),
      ("loop", tkKwLoop),
      ("each", tkKwEach),
      ("block", tkKwBlock),
      ("run", tkKwRun),
      ("break", tkKwBreak),
      ("continue", tkKwContinue),
      ("true", tkKwTrue),
      ("false", tkKwFalse),
    ]
    for (word, expected) in kwTests:
      let tokens = tokenize(word)
      check tokens[0].typ == expected

  test "halt and typeof are identifiers, not keywords":
    let tokens = tokenize("halt")
    check tokens[0].typ == tkIdent
    check tokens[0].lexeme == "halt"

    let tokens2 = tokenize("typeof")
    check tokens2[0].typ == tkIdent
    check tokens2[0].lexeme == "typeof"

  test "case sensitivity":
    let tokens = tokenize("Health")
    check tokens[0].typ == tkIdent
    check tokens[0].lexeme == "Health"

    let tokens2 = tokenize("IF")
    check tokens2[0].typ == tkIdent
    check tokens2[0].lexeme == "IF"

  test "keyword prefix not matched as keyword":
    let tokens = tokenize("iffy")
    check tokens[0].typ == tkIdent
    check tokens[0].lexeme == "iffy"

    let tokens2 = tokenize("setter")
    check tokens2[0].typ == tkIdent
    check tokens2[0].lexeme == "setter"


suite "lexer - integer literals":

  test "simple integers":
    let tokens = tokenize("0")
    check tokens[0].typ == tkInt
    check tokens[0].intVal == 0

    let tokens2 = tokenize("42")
    check tokens2[0].typ == tkInt
    check tokens2[0].intVal == 42

    let tokens3 = tokenize("-7")
    check tokens3[0].typ == tkInt
    check tokens3[0].intVal == -7

  test "boundary max int64":
    when CakesparkIntBits == 64:
      let tokens = tokenize("9223372036854775807")
      check tokens[0].typ == tkInt
      check tokens[0].intVal == 9223372036854775807'i64

  test "boundary min int64":
    when CakesparkIntBits == 64:
      let tokens = tokenize("-9223372036854775808")
      check tokens[0].typ == tkInt
      check tokens[0].intVal == -9223372036854775808'i64

  test "overflow positive":
    when CakesparkIntBits == 64:
      var lex = newLexer("9223372036854775808")
      discard lex.nextToken()
      check lex.hasError
      check lex.errorMsg.contains("out of range")

  test "overflow negative":
    when CakesparkIntBits == 64:
      var lex = newLexer("-9223372036854775809")
      discard lex.nextToken()
      check lex.hasError
      check lex.errorMsg.contains("out of range")


suite "lexer - float literals":

  test "simple floats":
    let tokens = tokenize("3.14")
    check tokens[0].typ == tkFloat
    check abs(tokens[0].floatVal - 3.14) < 0.0001

    let tokens2 = tokenize("-0.5")
    check tokens2[0].typ == tkFloat
    check abs(tokens2[0].floatVal - (-0.5)) < 0.0001

    let tokens3 = tokenize("1.0")
    check tokens3[0].typ == tkFloat
    check abs(tokens3[0].floatVal - 1.0) < 0.0001

    let tokens4 = tokenize("0.0")
    check tokens4[0].typ == tkFloat
    check abs(tokens4[0].floatVal - 0.0) < 0.0001

  test "dot without leading zero is error":
    var lex = newLexer(".5")
    discard lex.nextToken()
    check lex.hasError
    check lex.errorMsg.contains("leading zero")

  test "trailing decimal point is error":
    var lex = newLexer("3.")
    discard lex.nextToken()
    check lex.hasError
    check lex.errorMsg.contains("trailing decimal")

  test "large float parses correctly":
    let tokens = tokenize("123456789.123456789")
    check tokens[0].typ == tkFloat


suite "lexer - string literals":

  test "simple string":
    let tokens = tokenize("\"hello\"")
    check tokens[0].typ == tkString
    check tokens[0].strParts.len == 1
    check tokens[0].strParts[0].isInterp == false
    check tokens[0].strParts[0].lit == "hello"

  test "empty string":
    let tokens = tokenize("\"\"")
    check tokens[0].typ == tkString
    check tokens[0].strParts.len == 0

  test "escape sequences":
    let tokens = tokenize("\"a\\\"b\\nc\\td\\\\e\"")
    check tokens[0].typ == tkString
    check tokens[0].strParts.len == 1
    check tokens[0].strParts[0].lit == "a\"b\nc\td\\e"

  test "unknown escape produces literal backslash":
    let tokens = tokenize("\"path\\x\\file\"")
    check tokens[0].typ == tkString
    check tokens[0].strParts.len == 1
    check tokens[0].strParts[0].lit == "path\\x\\file"

  test "interpolation":
    let tokens = tokenize("\"HP: {hp}\"")
    check tokens[0].typ == tkString
    check tokens[0].strParts.len == 2
    check tokens[0].strParts[0].isInterp == false
    check tokens[0].strParts[0].lit == "HP: "
    check tokens[0].strParts[1].isInterp == true
    check tokens[0].strParts[1].varName == "hp"

  test "multiple interpolations":
    let tokens = tokenize("\"{a} and {b}\"")
    check tokens[0].typ == tkString
    check tokens[0].strParts.len == 3
    check tokens[0].strParts[0].isInterp == true
    check tokens[0].strParts[0].varName == "a"
    check tokens[0].strParts[1].isInterp == false
    check tokens[0].strParts[1].lit == " and "
    check tokens[0].strParts[2].isInterp == true
    check tokens[0].strParts[2].varName == "b"

  test "escaped braces are literal":
    let tokens = tokenize("\"{{not interpolated}}\"")
    check tokens[0].typ == tkString
    check tokens[0].strParts.len == 1
    check tokens[0].strParts[0].isInterp == false
    check tokens[0].strParts[0].lit == "{not interpolated}"


suite "lexer - comments":

  test "full line comment":
    let tokens = tokenize("// this is a comment\nset")
    check tokens[0].typ == tkNewline
    check tokens[1].typ == tkKwSet
    check tokens[2].typ == tkEof

  test "inline comment":
    let tokens = tokenize("set 10 >> x  // inline\n")
    check tokens[0].typ == tkKwSet
    check tokens[1].typ == tkInt
    check tokens[2].typ == tkPipe
    check tokens[3].typ == tkIdent
    check tokens[3].lexeme == "x"
    check tokens[4].typ == tkNewline
    check tokens[5].typ == tkEof

  test "comment slashes inside string are not a comment":
    let tokens = tokenize("\"url: //example.com\"")
    check tokens[0].typ == tkString
    check tokens[0].strParts.len == 1
    check tokens[0].strParts[0].lit.contains("//")


suite "lexer - operators":

  test "pipe":
    let tokens = tokenize(">>")
    check tokens[0].typ == tkPipe
    check tokens[0].lexeme == ">>"

  test "comparison operators":
    let tests = [
      ("==", tkEq),
      ("!=", tkNeq),
      ("<", tkLt),
      (">", tkGt),
      ("<=", tkLte),
      (">=", tkGte),
    ]
    for (op, expected) in tests:
      let tokens = tokenize(op)
      check tokens[0].typ == expected


suite "lexer - punctuation":

  test "single char tokens":
    let tests = [
      ("[", tkLBracket),
      ("]", tkRBracket),
      ("(", tkLParen),
      (")", tkRParen),
      (",", tkComma),
      (".", tkDot),
    ]
    for (ch, expected) in tests:
      let tokens = tokenize(ch)
      check tokens[0].typ == expected

  test "dot followed by digit is error":
    var lex = newLexer(".5")
    discard lex.nextToken()
    check lex.hasError


suite "lexer - line endings":

  test "LF produces newline token":
    let tokens = tokenize("x\ny")
    check tokens[0].typ == tkIdent
    check tokens[0].lexeme == "x"
    check tokens[1].typ == tkNewline
    check tokens[2].typ == tkIdent
    check tokens[2].lexeme == "y"

  test "CRLF produces single newline token":
    let tokens = tokenize("x\r\ny")
    check tokens[0].typ == tkIdent
    check tokens[0].lexeme == "x"
    check tokens[1].typ == tkNewline
    check tokens[2].typ == tkIdent
    check tokens[2].lexeme == "y"

  test "bare CR is error":
    var lex = newLexer("x\ry")
    discard lex.nextToken()
    discard lex.nextToken()
    check lex.hasError
    check lex.errorMsg.contains("bare CR")


suite "lexer - error cases":

  test "invalid character":
    var lex = newLexer("@")
    discard lex.nextToken()
    check lex.hasError
    check lex.errorMsg.contains("unexpected character")

  test "unterminated string":
    var lex = newLexer("\"hello")
    discard lex.nextToken()
    check lex.hasError
    check lex.errorMsg.contains("unterminated string")

  test "lone equals sign":
    var lex = newLexer("=")
    discard lex.nextToken()
    check lex.hasError
    check lex.errorMsg.contains("=")

  test "lone bang":
    var lex = newLexer("!")
    discard lex.nextToken()
    check lex.hasError
    check lex.errorMsg.contains("!")


suite "lexer - full scripts":

  test "multi-line script":
    let source = "set 10 >> x\n" &
                 "add x 5 >> result\n" &
                 "log \"the answer is {result}\"\n"
    let tokens = tokenize(source)
    check tokens[0].typ == tkKwSet
    check tokens[1].typ == tkInt
    check tokens[1].intVal == 10
    check tokens[2].typ == tkPipe
    check tokens[3].typ == tkIdent
    check tokens[3].lexeme == "x"
    check tokens[4].typ == tkNewline

    check tokens[5].typ == tkIdent
    check tokens[5].lexeme == "add"
    check tokens[6].typ == tkIdent
    check tokens[6].lexeme == "x"
    check tokens[7].typ == tkInt
    check tokens[7].intVal == 5
    check tokens[8].typ == tkPipe
    check tokens[9].typ == tkIdent
    check tokens[9].lexeme == "result"
    check tokens[10].typ == tkNewline

    check tokens[11].typ == tkIdent
    check tokens[11].lexeme == "log"
    check tokens[12].typ == tkString
    check tokens[13].typ == tkNewline

  test "token positions are tracked":
    var lex = newLexer("set 10 >> x\nadd x 5")
    let t1 = lex.nextToken()
    check t1.line == 1
    check t1.col == 1
    check t1.lexeme == "set"

    let t2 = lex.nextToken()
    check t2.line == 1
    check t2.col == 5
    check t2.lexeme == "10"

    let t3 = lex.nextToken()
    check t3.line == 1
    check t3.col == 8
    check t3.lexeme == ">>"

    let t4 = lex.nextToken()
    check t4.line == 1
    check t4.col == 11
    check t4.lexeme == "x"

    let t5 = lex.nextToken()
    check t5.typ == tkNewline
    check t5.line == 1

    let t6 = lex.nextToken()
    check t6.line == 2
    check t6.col == 1
    check t6.lexeme == "add"

  test "BOM is rejected":
    let source = "\uFEFFset 10 >> x"
    let tokens = tokenize(source)
    check tokens.len == 1
    check tokens[0].typ == tkEof
