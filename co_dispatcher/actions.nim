from co_protocol.pipeproto import Task, Answer
from cache import ModuleCache

proc runTask*(cache: ModuleCache, task: Task): Answer
proc prepareTask*(cache: ModuleCache, task: Task): Answer

from co_protocol.pipeproto import DispatcherAnswerType
from tables import `[]`
from detector import feedData
import co_protocol.modproto

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
