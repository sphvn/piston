{span} = require 'prelude-ls' .Str
{drop} = require 'prelude-ls'

# export length, and define for internal use also
@length = length = (.length)

# exclusive span
@exspan = (c, xs) ->
  [x, y] = span (!= c), xs
  [x, drop (length c), y]

# convert array-like to array
@to-array = (x) -> Array.prototype.slice.call x