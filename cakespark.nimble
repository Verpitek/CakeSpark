version       = "1.0.0"
author        = "Matas Petraitis (Verpitek MB)"
description   = "CakeSpark sandboxed scripting language VM — spec 1.0.0"
license       = "Prosperity-3.0.0"
srcDir        = "src"
bin           = @["cakespark"]

requires "nim >= 2.0.0"

task test, "Run all tests":
  exec "nim c --path:src -r tests/test_lexer.nim"
  exec "nim c --path:src -r tests/test_parser.nim"
  exec "nim c --path:src -r tests/test_compiler.nim"
  exec "nim c --path:src -r tests/test_vm.nim"
  exec "nim c --path:src -r tests/test_functions.nim"
  exec "nim c --path:src -r tests/test_controlflow.nim"
  exec "nim c --path:src -r tests/test_strings.nim"
  exec "nim c --path:src -r tests/test_arrays.nim"
  exec "nim c --path:src -r tests/test_execution.nim"
  exec "nim c --path:src -r tests/test_peripheral.nim"
  exec "nim c --path:src -r tests/test_integration.nim"

task test_lexer, "Run lexer tests":
  exec "nim c --path:src -r tests/test_lexer.nim"

task test_parser, "Run parser tests":
  exec "nim c --path:src -r tests/test_parser.nim"

task test_compiler, "Run compiler tests":
  exec "nim c --path:src -r tests/test_compiler.nim"

task test_vm, "Run VM tests":
  exec "nim c --path:src -r tests/test_vm.nim"

task test_sizes, "Run byte-size target tests (i32)":
  exec "nim c -d:cakesparkIntBits=32 --path:src -r tests/test_sizes.nim"

task test_sizes_i64, "Run byte-size target tests (i64)":
  exec "nim c -d:cakesparkIntBits=64 --path:src -r tests/test_sizes.nim"

task test_sizes_nofloat, "Run byte-size target tests (no float)":
  exec "nim c -d:cakesparkNoFloat --path:src -r tests/test_sizes.nim"

task test_direct, "Run direct mode tests (i64)":
  exec "nim c -d:cakesparkDirect --path:src -r tests/test_direct.nim"

task test_direct_i32, "Run direct mode tests (i32)":
  exec "nim c -d:cakesparkDirect -d:cakesparkIntBits=32 --path:src -r tests/test_direct.nim"

task test_all, "Run full test matrix":
  exec "nim c --path:src -r tests/test_lexer.nim"
  exec "nim c --path:src -r tests/test_parser.nim"
  exec "nim c --path:src -r tests/test_compiler.nim"
  exec "nim c --path:src -r tests/test_vm.nim"
  exec "nim c --path:src -r tests/test_functions.nim"
  exec "nim c --path:src -r tests/test_controlflow.nim"
  exec "nim c --path:src -r tests/test_strings.nim"
  exec "nim c --path:src -r tests/test_arrays.nim"
  exec "nim c --path:src -r tests/test_execution.nim"
  exec "nim c --path:src -r tests/test_peripheral.nim"
  exec "nim c --path:src -r tests/test_integration.nim"
  exec "nim c -d:cakesparkIntBits=32 --path:src -r tests/test_sizes.nim"
  exec "nim c -d:cakesparkNoFloat --path:src -r tests/test_sizes.nim"
  exec "nim c -d:cakesparkDirect --path:src -r tests/test_direct.nim"
  exec "nim c -d:cakesparkDirect -d:cakesparkIntBits=32 --path:src -r tests/test_direct.nim"

task header, "Generate C header":
  exec "echo '#include/cakespark.h is hand-maintained; see include/cakespark.h'"
