when defined(module):
  discard
else:
  from co_protocol.signature import checkSignature, sign
  from co_protocol.pipeproto import SignedRequest, Task, ReqType, Pair, TaskId,
                                    Answer, DispatcherAnswerType, serialize,
                                    deserialize
  from random import random, randomize
  from osproc import startProcess, inputStream, outputStream, waitForExit,
                     hasData, close
  from streams import flush
  from ospaths import getEnv
  import unittest
  randomize()
  let signatureFile = getEnv("COSIGNATURE")
  let dispatcher = getEnv("DISPATCHER")
  suite "Signature checking":
    test "Simple signature checking":
      let t: Task = (name: "test", module: "tmod", nprocs: 0'u8, memory: 0'u32,
                     params: newSeq[Pair]())
      let r = SignedRequest(passhash: "", time: random(10000).uint32, kind: Run,
                            task: t)
      let signed = r.sign()
      check(signed.checkSignature())

    test "Dispatcher checking":
      let r = SignedRequest(passhash: "", time: random(10000).uint32,
                            kind: Status, id: random(10000).TaskId)
      let signed = r.sign()
      let p = startProcess(dispatcher, args = ["-d"])
      let input = p.inputStream()
      signed.serialize(input)
      input.flush() # Do not forget to flush the input stream to push forward
                    # serialized data to the process!
      let output = p.outputStream()
      let ecode = p.waitForExit(1000)
      require(ecode == 0)
      require(p.hasData())
      let answer = Answer.deserialize(output)
      p.close()
      check(answer.kind == Done)
