
when defined(module):
  from os import paramCount, paramStr
  if paramCount() == 1 and paramStr(1) == "-n":
    echo """{"""
    echo """  "name": "dummy","""
    echo """  "description": "Dummy module for tests","""
    echo """  "extensions": [],"""
    echo """  "reqFields": [],"""
    echo """  "optionalFields": [],"""
    echo """}"""
else:
  from co_protocol.pipeproto import deserialize, ModuleInfo, size,
                                    Answer, DispatcherAnswerType
  from osproc import startProcess, poEvalCommand, outputStream, close, hasData,
                     waitForExit
  from ospaths import getEnv
  from strtabs import newStringTable, modeCaseSensitive
  from streams import setPosition, readAll
  import unittest

  let envTable = newStringTable("COMODULEPATH", "./modules", modeCaseSensitive)
  let dispatcherExecutable = getEnv("DISPATCHER")
  
  suite "Initialization tests":
    test "Simple initialization":
      let m: ModuleInfo = (name: "dummy", description: "Dummy module for tests",
                           extensions: @[], reqFields: @[], optionalFields: @[])
      let d = Answer(kind: Abilities, modules: @[m])
      let p = startProcess(dispatcherExecutable, args = ["-i"], env = envTable)
      let outputStream = p.outputStream()
      let exitcode = p.waitForExit(1)
      require(exitcode == 0)
      require(p.hasData())
      let dsd = Answer.deserialize(outputStream)
      p.close()
      require(dsd.kind == d.kind)
      require(dsd.modules.len == d.modules.len)
      let dsm = dsd.modules[0]
      check(dsm.name == m.name)
      check(dsm.description == m.description)
      check(dsm.extensions == m.extensions)
      check(dsm.reqFields == m.reqFields)
      check(dsm.optionalFields == m.optionalFields)

