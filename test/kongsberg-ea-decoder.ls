codec  = require "../decoders/kongsberg-ea.js"
moment = require \moment
should = require \chai .should!

protocol = "Simrad EA ASCII"

describe 'the kongsberg-ea.decode', (_) ->
  it 'should return multiple decoded Sounder messages', (done) ->
    given = "D1,02281207,  7.51,-22,  1,  0,18,5.00,1500.0* 4\r\nD2,02281207,  7.85,-18,  1,  0,38,5.00,1500.0* 5\r\nD3,02281207,  7.50,-17,  1,  0,200,5.00,1500.0*3A\r\n"
    expected = ["D1,02281207,  7.51,-22,  1,  0,18,5.00,1500.0* 4", "D2,02281207,  7.85,-18,  1,  0,38,5.00,1500.0* 5", "D3,02281207,  7.50,-17,  1,  0,200,5.00,1500.0*3A"]
    result = codec.receive given
    result.should.eql expected
    done!

describe 'the kongsberg-ea.decode', (_) ->
  it 'should return the decoded Sounder message', (done) ->
    given = "D1,02281207,  7.51,-22,  1,  0,18,5.00,1500.0* 4"
    expected = {
      talker         : ""
      sentence       : protocol
      time           : moment "02281207", "HHmmssSS"
      channel        : 1
      depth          : 7.51
      backscatter    : -22
      transducer     : 1
      slope          : 0
      frequency      : 18
      draft          : 5.00
      speed-of-sound : 1500.0
    }
    result = codec.decode given
    result.should.eql expected
    done!

  it 'should decode sequential Sounder message', (done) ->
    codec.flush!
    given = "D1,02281207,  7.51,-22,  1,  0,18,5.00,1500.0* 4\r\nD2,02281207,  7.85,-18,  1,  0,38,5.00,1500.0* 5\r\nD3,02281207,  7.50,-17,  1,  0,200,5.00,1500.0*3A\r\n"
    expected = {
      talker         : ""
      sentence       : protocol
      time           : moment "02281207", "HHmmssSS"
      channel        : 1
      depth          : 7.51
      backscatter    : -22
      transducer     : 1
      slope          : 0
      frequency      : 18
      draft          : 5.00
      speed-of-sound : 1500.0
    }
    result = codec.decode given
    result.should.eql expected
    codec.flush!
    given = "D2,02281207,  7.85,-18,  1,  0,38,5.00,1500.0* 5\r\nD3,02281207,  7.50,-17,  1,  0,200,5.00,1500.0*3A\r\n"
    expected = {
      talker         : ""
      sentence       : protocol
      time           : moment "02281207", "HHmmssSS"
      channel        : 2
      depth          : 7.85
      backscatter    : -18
      transducer     : 1
      slope          : 0
      frequency      : 38
      draft          : 5.00
      speed-of-sound : 1500.0
    }
    result = codec.decode given
    result.should.eql expected
    codec.flush!
    given = "D3,02281207,  7.50,-17,  1,  0,200,5.00,1500.0*3A\r\n"
    expected = {
      talker         : ""
      sentence       : protocol
      time           : moment "02281207", "HHmmssSS"
      channel        : 3
      depth          : 7.50
      backscatter    : -17
      transducer     : 1
      slope          : 0
      frequency      : 200
      draft          : 5.00
      speed-of-sound : 1500.0
    }
    result = codec.decode given
    result.should.eql expected
    done!
