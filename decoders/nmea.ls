{drop-while, take-while} = require 'prelude-ls' .Str

buffer = ""
@unchunk = (chunk) ->
  buffer += chunk
  buffer  := drop-while (!= "$"), buffer
  message = take-while (!= ";"), buffer
  if (message.length >= 1)
    buffer := drop-while (!= ";"), buffer
    message

@decode = (msg) ->
  msg