codec  = require "../decoders/kongsberg.js"
moment = require \moment
should = require \chai .should!

describe 'the kongsberg.decode', (_) ->
  it 'should return the decoded Sounder message', (done) ->
    given = "D1,02281207,  7.51,-22,  1,  0,18,5.00,1500.0* 4"
    expected = {
      talker      : ""
      sentence    : "Simrad ASCII"
      time        : moment "02281207", "HHmmssSS"
      channel     : 1
      depth       : 7.51
      backscatter : -22
      transducer  : 1
      slope       : 0
    }
    result = codec.decode given
    result.should.eql expected
    done!
