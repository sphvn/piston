server = require "../main.js"
moment = require "moment"
server.set-decoder "nmea"

describe 'the nmea.receive', (_) ->
  it 'should return the message when the chunk is the message', (done) ->
    server.decoder.flush!
    expected = "$HEHDT,289.97,T*12"
    given = "#expected\r"
    result = server.decoder.receive given
    result.should.equal expected
    done!

  it 'should return the message when the chunk contains the message', (done) ->
    server.decoder.flush!
    expected = "$HEHDT,289.97,T*12"
    given = ",T*12\r#expected\r$HEHDT,2"
    result = server.decoder.receive given
    result.should.equal expected
    done!

  it 'should return the message from multiple chunks', (done) ->
    server.decoder.flush!
    expected = "$HEHDT,289.97,T*12";
    msg1 = ",T*12\r";
    msg2 = "$HEHDT,289";
    msg3 = ".97,T*12";
    msg4 = "\r$HEHDT,2";
    result = server.decoder.receive msg1
    result = server.decoder.receive msg2
    result = server.decoder.receive msg3
    result = server.decoder.receive msg4
    result.should.equal expected
    done!

  it 'should flush the buffer if it reaches 16k', (done) ->
    server.decoder.flush!
    for _ from 0 to 16000
      m = server.decoder.receive \0
    result = server.decoder.buffer-size
    result.should.equal 0
    done!

  it 'should handle a null character in chunk', (done) ->
    # outside message
    server.decoder.flush!
    expected = "$HEHDT,289.97,T*12";
    result = server.decoder.receive "#expected\rA\0Z"
    result.should.equal expected
    # inside message
    server.decoder.flush();
    expected_ = "$HEHDT,289.97,\0T*12";
    result_ = server.decoder.receive "#expected_\r"
    result_.should.equal(expected_)
    done!

  it 'should handle a null chunk', (done) ->
    server.decoder.flush!
    expected = null
    result = server.decoder.receive expected
    (result == null).should.be.true
    done!

describe 'the nmea.decode', (_) ->
  it 'should return the decoded HDT', (done) ->
    given = "$HEHDT,289.97,T*12"
    obj = {
      talker       : "HE"
      sentence     : "HDT"
      heading      : 289.97
      heading-type : "T"
    }
    expected = JSON.stringify obj
    result = JSON.stringify (server.decoder.decode given)
    result.should.equal expected
    #obj.should.equal (server.decoder.decode given)
    done!

  it 'should return the decoded GGA', (done) ->
    given = "$GPGGA,175621.13,3254.12,S,11530.00,E,2,10,0.9,31.30,M,-33.13,M,020,1000*56"
    obj = {
      talker      : "GP"
      sentence    : "GGA"
      time        : moment.utc h: 17, m: 56, s: 21, ms: 130
      wgs84       : lat: -32.902, lon: 115.5, elh: 31.30+(-33.13)
      quality     : [2, "Differential"]
      satellites  : 10
      hdop        : 0.9
      correction-age    : 20
      reference-station : 1000
    }
    expected = JSON.stringify obj
    result = JSON.stringify (server.decoder.decode given)
    result.should.equal expected
    done!

  it 'should return null if checksum is invalid', (done) ->
    given = "$HEHDT,289.97,T*13"
    expected = null
    result = server.decoder.decode given
    (result == null).should.be.true
    done!