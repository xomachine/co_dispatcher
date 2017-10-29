from cache import Module
from osproc import Process

proc enumerateModules*(): seq[Module]
proc feedData*(executable: string, data: string = nil): string
proc feedAndWait*(executable, data: string, onIteration: proc (p: Process))

from ospaths import getEnv, existsEnv, `/` , getConfigDir
from osproc import startProcess, outputStream, ProcessOption, waitForExit,
                   hasData, close, inputStream, running
from os import walkFiles, getFilePermissions, FilePermission, sleep
from streams import readAll, write
from co_protocol.pipeproto import ModuleInfo
import co_protocol.modproto

const modulePathEnvName = "COMODULEPATH"

let defaultModulesDir = getConfigDir() / "Cooperation" / "modules"
let modulePath = if existsEnv(modulePathEnvName): getEnv(modulePathEnvName)
                 else: defaultModulesDir

proc enumerateModules(): seq[Module] =
  result = newSeq[Module]()
  for file in walkFiles(modulePath / "*"):
    if fpUserExec in file.getFilePermissions():
      let data = file.feedData()
      if not data.isNil:
        var module: ModuleInfo
        try:
          fromJson(module, data.parseJson())
          result.add((path: file, modinfo: module))
        except DeserializeError:
          stderr.writeLine("Can not deserialize file:" & file & "!")
          stderr.writeLine(getCurrentExceptionMsg())
      else:
        stderr.writeLine("Can not get info from " & file)

proc startWithData(executable, data: string): Process =
  let args = if data.isNil: @["-n"] else: @[]
  let process = startProcess(executable, args = args, options = {poDemon})
  if not data.isNil:
    let inputStream = process.inputStream()
    inputStream.write(data)
  process

proc feedData(executable: string, data: string = nil): string =
  let process = startWithData(executable, data)
  let exitcode = process.waitForExit(500)
  if exitcode == 0 and process.hasData():
    let responceStream = process.outputStream()
    result = responceStream.readAll()
  process.close()

proc feedAndWait(executable, data: string, onIteration: proc (p: Process)) =
  let process = startWithData(executable, data)
  while process.running():
    onIteration(process)
    sleep(1000)
