server = require "../main.js"
server.set-decoder "nmea"

describe 'the decoder unchunker', (test) ->
  it 'should return the message when the chunk is the message', (done) ->
    expected = "$HEHDT,289.97,T*12"
    given = "#expected\r"
    server.decoder.flush!
    result = server.decoder.receive given
    result.should.equal expected
    done!

  it 'should return the message when the chunk contains the message', (done) ->
    expected = "$HEHDT,289.97,T*12"
    given = ",T*12\r#expected\r$HEHDT,2"
    server.decoder.flush!
    result = server.decoder.receive given
    result.should.equal expected
    done!

  it 'should return the message from multiple chunks', (done) ->
    expected = "$HEHDT,289.97,T*12";
    msg1 = ",T*12\r";
    msg2 = "$HEHDT,289";
    msg3 = ".97,T*12";
    msg4 = "\r$HEHDT,2";
    server.decoder.flush!
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
