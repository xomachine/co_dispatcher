from co_protocol.pipeproto import Task, Answer
from cache import ModuleCache

proc runTask*(cache: ModuleCache, task: Task): Answer
proc prepareTask*(cache: ModuleCache, task: Task): Answer

from co_protocol.signature import checkSignature
from co_protocol.pipeproto import DispatcherAnswerType, SignedRequest,
                                  deserialize
from tables import `[]`
from detector import feedData
from macros import nnkOfBranch, expectKind, expectMinLen, insert, `[]`, newTree,
                   hint, children, quote, kind, treeRepr, nnkPar
import co_protocol.modproto

macro generalDispatch*(request: SignedRequest, matches: typed): untyped =
  ## Checks `request`'s signature and dispatches it according the `matches`.
  ## The `matches` should follow the pattern:
  ##
  ##.. code-block:: nim
  ##  generalDispatch(request, {
  ##      requestKind1: action1(),
  ##      requestKind2: action2()
  ##    })
  ##
  ## The code generated by macro returns an `Answer`. All invalid requests
  ## (including bad signed or not mentioned in `matches`) will be handled
  ## automatically.
  var caseStmt = quote do:
    case `request`.kind
    else:
      Answer(kind: Error, description: "Unexpected request type!")
  for m in matches.children():
    let match = m[1]
    match.expectKind(nnkPar)
    match.expectMinLen(2)
    let branch = newTree(nnkOfBranch, match[0], match[1])
    caseStmt.insert(1, branch)
  result = quote do:
    if `request`.checkSignature():
      `caseStmt`
    else:
      Answer(kind: NotAuthorized)
  when defined(debug): hint(result.treeRepr)

proc runTask(cache: ModuleCache, task: Task): Answer =
  discard

proc prepareTask(cache: ModuleCache, task: Task): Answer =
  ## The task preparation is the way to obtain task requirements from
  ## task-related files. It should be done once the task is added to
  ## the queue first time.
  ## The result of task preparation should be the updated task description
  ## structure with correct requirements inside.
  result.kind = Error
  let executable = cache[task.module].path
  let message: TaskMessage = (action: "prepare", task: task)
  let input = $toJson(message)
  let reply = executable.feedData(input)
  if not reply.isNil:
    var answer: TaskMessage
    try:
      fromJson(answer, reply.parseJson())
      result.kind = Prepared
      result.task = answer.task
    except DeserializeError:
      result.description = getCurrentExceptionMsg()
  else:
    result.description = "The module does not replied for request!"
