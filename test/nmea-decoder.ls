server = require "../main.js"
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
  it 'should return the decoded object', (done) ->
    given = "$HEHDT,289.97,T*12"
    obj = {
      talkerId    : "HEHDT"
      heading     : "289.97"
      headingType : "T"
      checksum    : "12"
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