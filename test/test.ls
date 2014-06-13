qc     = require \quickcheck
assert = require \assert
#import "server.js"

describe "should return null when there is no terminator" ->
  expected = null
  given    = ",289.97,T"
  result   = unchunker given
  assert.equal expected, result

describe "should convert chunks into whole message" ->
  expected = "$HEHDT,289.97,T*12;"
  given    = ",T*12;#{er}$HEHDT,2"
  result   = unchunker given
  assert.equal expected, result

