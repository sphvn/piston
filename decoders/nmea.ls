{drop-while, take-while, span} = require 'prelude-ls' .Str
{drop} = require 'prelude-ls'

length = (.length)
exspan = (c, xs) ->
  [x, y] = span (!= c), xs
  [x, drop (length c), y]

buffer = ""
@buffer-size = length buffer
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
  _msg = drop 1 msg
  [_msg, checksum] = exspan '*' _msg
  return null if invalid checksum, _msg
  [talkerId,    _msg]     = exspan ',' _msg
  [heading,     _msg]     = exspan ',' _msg
  [headingType, _] = exspan '*' _msg
  {
    talkerId    : talkerId
    heading     : heading
    headingType : headingType
    checksum    : checksum
  }

invalid = (cs, msg) -> (checksum msg) != cs

checksum = (xs) ->
  x = 0
  for i from 0 to xs.length - 1
    x = x .^. xs.char-code-at i

  hex = Number x .to-string 16 .to-upper-case!
  if hex.length < 2
    (\00 + hex).slice -2
  else
    hex
