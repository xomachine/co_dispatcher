# Package

version       = "0.1.0"
author        = "xomachine"
description   = "Dispatcher module of the Cooperation package"
license       = "MIT"

bin           = @["co_dispatcher/codispatcher"]
skipDirs      = @["tests"]
# Dependencies

requires "nim >= 0.17.3"
requires "co_protocol"

task tests, "Run tests":
  exec("nimble build")
  let test_files = listFiles("tests")
  let executable = bin[0]
  mkDir("modules")
  mkDir("cache")
  for file in test_files:
    exec("nim c -d:module -o:modules/testmodule " & file)
    exec("export DISPATCHER=" & executable & "; export COMODCACHE=" &
         thisDir() & "/cache/modules.cache" & "; export COSIGNATURE=" &
         thisDir() & "/signature.key; nim c --run -o:tmpfile -p:" &
         thisDir() & " " & file)
    rmFile("tmpfile")
    rmFile("cache/modules.cache")
    rmFile("signature.key")
    rmFile("modules/testmodule")
  rmDir("cache")
  rmDir("modules")
