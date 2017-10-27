from co_protocol.pipeproto import ModuleInfo

proc enumerateModules*(): seq[ModuleInfo]

from ospaths import getEnv, existsEnv, `/` , getConfigDir
from osproc import startProcess, outputStream, ProcessOption, waitForExit,
                   hasData, close
from os import walkFiles, getFilePermissions, FilePermission, sleep
from streams import readAll
import co_protocol.modproto

const modulePathEnvName = "COMODULEPATH"

let defaultModulesDir = getConfigDir() / "Cooperation" / "modules"
let modulePath = if existsEnv(modulePathEnvName): getEnv(modulePathEnvName)
                 else: defaultModulesDir

proc enumerateModules(): seq[ModuleInfo] =
  result = newSeq[ModuleInfo]()
  for file in walkFiles(modulePath / "*"):
    if fpUserExec in file.getFilePermissions():
      let process = startProcess(file, args = ["-n"],
        options = {poDemon})
      let exitcode = process.waitForExit(500)
      if exitcode == 0 and process.hasData():
        let responceStream = outputStream(process)
        let data = responceStream.readAll()
        var module: ModuleInfo
        try:
          fromJson(module, data.parseJson())
          result.add(module)
        except DeserializeError:
          stderr.writeLine("Can not deserialize file:" & file & "!")
          stderr.writeLine(getCurrentExceptionMsg())
      else:
        stderr.writeLine("Can not get info from " & file)
      process.close()

