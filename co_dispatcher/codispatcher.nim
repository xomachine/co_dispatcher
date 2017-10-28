from streams import newFileStream
from parseopt import getopt, cmdShortOption, cmdLongOption
from ospaths import getEnv, existsEnv, getTempDir, `/`, splitPath
from os import paramCount, fileExists, createDir
from co_protocol.pipeproto import serialize, deserialize
from co_protocol.pipeproto import DispatcherAnswerType, SignedRequest, Answer
from co_protocol.pipeproto import ModuleInfo, ReqType
from co_protocol.signature import checkSignature
from cache import info, load, save, fill, ModuleCache
from actions import runTask, prepareTask

proc exitAndUsage() =
  quit("No manual call of this program allowed.")

proc printHelp() =
  echo """Cooperation dispatcher - a tool for dispatching users tasks""" &
    """ to modules.

It should not be called manually. Only Cooperation server can call it in""" &
    """ proper way."""

if paramCount() == 0:
  exitAndUsage()

let cachefile =
  if existsEnv("COMODCACHE"):
    getEnv("COMODCACHE")
  else: getTempDir() / "Cooperation" / "modules.cache"

let modcache =
  if fileExists(cachefile):
    try:
      load(cachefile)
    except:
      ModuleCache.fill()
  else:
    ModuleCache.fill()

proc performInitialization() =
  ## This proc should perform search of modules in folders specified by
  ## environment variables and then asks all detected modules for module
  ## information. After that it writes to standart output all collected
  ## module information in serialized form.
  let output = newFileStream(stdout)
  let info = Answer(kind: Abilities, modules: modcache.info())
  info.serialize(output)

proc dispatch() =
  ## Receives request from stdin and checks its signature. If check is passed
  ## then converts request to json and dispatches it to the module.
  let input = newFileStream(stdin)
  let output = newFileStream(stdout)
  let request = SignedRequest.deserialize(input)
  let answer = 
    if request.checkSignature():
      case request.kind
      of Run:
        modcache.runTask(request.task)
      of Prepare:
        modcache.prepareTask(request.task)
      of Remove, Status:
        # Just a signature checking should be performed
        Answer(kind: Done)
      else:
        Answer(kind: Error, description: "Unexpected request type!")
    else:
      Answer(kind: NotAuthorized)
  answer.serialize(output)

for kind, key, val in getopt():
  case kind
  of cmdShortOption, cmdLongOption:
    case key
    of "i", "init":
      performInitialization()
    of "d", "dispatch":
      dispatch()
    of "h", "help":
      printHelp()
    else:
      exitAndUsage()
  else:
    exitAndUsage()

try:
  createDir(cachefile.splitPath().head)
  modcache.save(cachefile)
except AssertionError:
  stderr.writeLine("Can not save module cache:\n" & getCurrentExceptionMsg())
