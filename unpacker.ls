{drop-while, span} = require 'prelude-ls' .Str

@unpack = (buf, chunk, sc, ec) ->
  _buf = drop-while (!= sc), buf + chunk
  return [_buf, null] if (_buf.index-of ec) == -1
  
  [msg, _buf] = span (!= ec), _buf
  switch
  | msg[0] == sc => [_buf, msg]
  | otherwise    => [_buf, null]