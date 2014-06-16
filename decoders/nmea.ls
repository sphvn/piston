{drop-while, take-while, span} = require 'prelude-ls' .Str

buffer = ""
@buffer-size = buffer.length
@flush = -> buffer := ""

@receive = (chunk) ->
  flush! if @buffer-size > 16000

  [buf, msg] = unpack buffer, chunk
  buffer := buf
  msg

unpack = (buf, chunk) ->
  _buf = drop-while (!= "$"), buf + chunk
  return [_buf, null] if (_buf.index-of "\r") == -1
  
  [msg, _buf] = span (!= "\r"), _buf
  switch
  | msg[0] == "$" => [_buf, msg]
  | otherwise     => [_buf, null]


@decode = (msg) ->
  msg