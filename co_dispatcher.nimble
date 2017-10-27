# Package

version       = "0.1.0"
author        = "xomachine"
description   = "Dispatcher module of the Cooperation package"
license       = "MIT"

bin           = @["co_dispatcher/codispatcher"]
# Dependencies

requires "nim >= 0.17.3"
requires "co_protocol"

task tests, "Run tests":
  exec("nimble build")
  let test_files = listFiles("tests")
  let executable = bin[0]
  mkDir("modules")
  for file in test_files:
    exec("nim c -d:module -o:modules/testmodule " & file)
    exec("export DISPATCHER=" & executable & "; nim c --run -o:tmpfile -p:" &
         thisDir() & " " & file)
    rmFile("tmpfile")
    rmFile("modules/testmodule")
  rmDir("modules")
