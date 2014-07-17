{drop-while, span} = require 'prelude-ls' .Str
{length, to-array} = require '../prelude-ext.js'
{unpack} = require '../unpacker.js'
moment = require 'moment'

unpack-kongsberg = (b, c) -> unpack.apply @, (to-array arguments) ++ ['D' '\r']

buffer = ""
@buffer-size = -> length buffer
@flush = -> buffer := ""

@receive = (chunk) ->
  @flush! if @buffer-size! >= 16000
  msgs = []
  loop
    [buf, msg] = buffer `unpack-kongsberg` chunk
    buffer := buf
    return msgs unless msg?
    msgs.push msg
    chunk := ""

@decode = (msg) ->
  talker         = ""
  sentence       = "Simrad EA ASCII"
  parts          = msg.split ','

  { talker, sentence } <<<
    time           : moment parts[1], "HHmmssSS"
    channel        : parse-int parts[0].substr(1)
    depth          : parse-float parts[2]
    backscatter    : parse-float parts[3]
    transducer     : parse-int parts[4]
    slope          : parse-int parts[5]
    frequency      : parse-int parts[6]
    draft          : parse-float parts[7]
    speed-of-sound : parse-float parts[8]
