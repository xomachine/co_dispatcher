from co_protocol.pipeproto import Task, Answer

proc runTask*(task: Task): Answer
proc prepareTask*(task: Task): Answer


proc runTask(task: Task): Answer =
  discard

proc prepareTask(task: Task): Answer =
  discard
