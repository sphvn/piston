# Decoder for Kongsberg sounder strings
# DJC 18-Jun-2014

{drop-while, span} = require 'prelude-ls' .Str
moment = require 'moment'

length = (.length)

start-char = "D"
end-char = "\r"

buffer = ""
@buffer-size = -> length buffer
@flush = -> buffer := ""

@receive = (chunk) ->
  @flush! if @buffer-size! >= 16000
  msgs = []
  loop
    [buf, msg] = unpack buffer, chunk
    buffer := buf
    return msgs unless msg?
    msgs.push msg
    chunk := ""

unpack = (buf, chunk) ->
  _buf = drop-while (!= start-char), buf + chunk
  return [_buf, null] if (_buf.index-of end-char) == -1
  
  [msg, _buf] = span (!= end-char), _buf
  switch
  | msg[0] == start-char => [_buf, msg]
  | otherwise            => [_buf, null]


@decode = (msg) ->
  talker         = ""
  sentence       = "Simrad ASCII"
  parts          = msg.split(",")

  { talker, sentence } <<<
    time        : moment parts[1], "HHmmssSS"
    channel     : parse-int parts[0].substr(1)
    depth       : parse-float parts[2]
    backscatter : parse-float parts[3]
    transducer  : parse-int parts[4]
    slope       : parse-int parts[5]
