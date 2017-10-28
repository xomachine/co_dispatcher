from nesm import serializable
from co_protocol.pipeproto import ModuleInfo
from tables import Table

serializable:
  type
    Module* = tuple
      path: string
      modinfo: ModuleInfo
    Pair = tuple
      key: string
      value: Module
    FlatModuleCache = seq[Pair]

type ModuleCache* = Table[string, Module]

proc load*(filename: string): ModuleCache
proc save*(self: ModuleCache, filename: string)
proc fill*(self: typedesc[ModuleCache]): ModuleCache
proc info*(self: ModuleCache): seq[ModuleInfo]

from sequtils import toSeq
from streams import newFileStream, close
from tables import pairs, len, toTable, initTable, `[]=`
from detector import enumerateModules
from math import nextPowerOfTwo

proc info(self: ModuleCache): seq[ModuleInfo] =
  ## Returns list of `ModuleInfo` structures to send it via the `Abilities`
  ## answer.
  result = newSeq[ModuleInfo](self.len)
  var i = 0
  for k, v in self.pairs():
    result[i] = v.modinfo
    i += 1

proc load(filename: string): ModuleCache =
  ## Loads `ModuleCache` from given file.
  let fd = newFileStream(filename, fmRead)
  assert(not fd.isNil, "Can not open file for read: " & filename)
  let flatCache = FlatModuleCache.deserialize(fd)
  toTable(flatCache)

proc save(self: ModuleCache, filename: string) =
  ## Writes module cache to given file by replacing its content. If file
  ## does not exist, it will be created.
  var flatCache: FlatModuleCache = newSeq[Pair](self.len)
  var i = 0
  for k, v in pairs(self):
    flatCache[i] = (key: k, value: v)
    i += 1
  let fd = newFileStream(filename, fmWrite)
  assert(not fd.isNil, "Can not open file for write: " & filename)
  flatCache.serialize(fd)
  fd.close()

proc fill*(self: typedesc[ModuleCache]): ModuleCache =
  ## Runs detector procedure and fills the `ModuleCache` with information
  ## about detected modules.
  let modules = enumerateModules()
  result = initTable[string, Module](nextPowerOfTwo(modules.len))
  for module in modules:
    result[module.modinfo.name] = module

