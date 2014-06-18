# Decoder for TSS 320 sounder string
# DJC 18-Jun-2014

{drop-while, span} = require 'prelude-ls' .Str
moment = require 'moment'

length = (.length)

start-char = ":"
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
  sentence       = "TSS-Sounder"
  _identifier    = msg.substr(1, 6)
  _depth         = msg.substr(8, 6)
  _corr-depth    = msg.substr(15, 6)
  _heave         = msg.substr(22, 5)
  _quality       = msg.substr(27, 1)
  _roll          = msg.substr(28, 5)
  _pitch         = msg.substr(34)

  { talker, sentence } <<<
    identifier: _identifier
    depth: (parse-float _depth) / 100.0
    corr-depth: (parse-float _corr-depth) / 100.0
    heave: (parse-float _heave) / 100.0
    quality: _quality
    pitch: (parse-float _pitch) / 100.0
    roll: (parse-float _roll) / 100.0
