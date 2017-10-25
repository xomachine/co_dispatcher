from streams import newFileStream
from parseopt import getopt, cmdShortOption, cmdLongOption
from co_protocol.pipeproto import serialize, deserialize
from co_protocol.pipeproto import DispatcherAnswerType, SignedRequest, Answer
from co_protocol.signature import checkSignature

proc exitAndUsage() =
  quit("No manual call of this program allowed.")

proc printHelp() =
  echo """Cooperation dispatcher - a tool for dispatching users tasks""" &
    """ to modules.

It should not be called manually. Only Cooperation server can call it in""" &
    """ proper way."""

proc performInitialization() =
  ## This proc should perform search of modules in folders specified by
  ## environment variables and then asks all detected modules for module
  ## information. After that it writes to standart output all collected
  ## module information in serialized form.
  discard

proc dispatch() =
  let input = newFileStream(stdin)
  let output = newFileStream(stdout)
  let request = SignedRequest.deserialize(input)
  if request.checkSignature():
    discard
  else:
    let reply = Answer(kind: NotAuthorized)
    reply.serialize(output)

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

