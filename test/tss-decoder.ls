codec  = require "../decoders/tss.js"
moment = require \moment
should = require \chai .should!

describe 'the tss.receive', (_) ->
  it 'should return the message when the chunk is the message', (done) ->
    codec.flush!
    expected = [":123456 123456 123456 -1234?-1234 -1234"]
    given = "#expected\r"
    result = codec.receive given
    result.should.eql expected
    done!

  it 'should return the message when the chunk contains the message', (done) ->
    codec.flush!
    expected = [":123456 123456 123456 -1234?-1234 -1234"]
    given = " 2222\r#expected\r:654321"
    result = codec.receive given
    result.should.eql expected
    done!

  it 'should return the message from multiple chunks', (done) ->
    codec.flush!
    expected = [":123456 123456 123456 -1234?-1234 -1234"];
    msg1 = " 2222\r";
    msg2 = ":123456 123456 ";
    msg3 = "123456 -1234?-1234 -1234";
    msg4 = "\r:654321";
    result = codec.receive msg1
    result = codec.receive msg2
    result = codec.receive msg3
    result = codec.receive msg4
    result.should.eql expected
    done!

  it 'should return messages when multiple messages in a chunk', (done) ->
    codec.flush!
    expected = [":123456 123456 123456 -1234?-1234 -1234", ":123456 123456 123456 -1234?-1234 -1234"]
    given = ":123456 123456 123456 -1234?-1234 -1234\r:123456 123456 123456 -1234?-1234 -1234\r"
    result = codec.receive given
    result.should.eql expected
    done!

  it 'should flush the buffer if it reaches 16k', (done) ->
    codec.flush!
    for _ from 0 to 16000
      m = codec.receive \0
    result = codec.buffer-size!
    result.should.equal 0
    done!

  it 'should handle a null character in chunk', (done) ->
    # outside message
    codec.flush!
    expected = [":123456 123456 123456 -1234?-1234 -1234"]
    result = codec.receive "#expected\rA\0Z"
    result.should.eql expected
    # inside message
    codec.flush();
    expected_ = [":123456 123456 123456 -1234?-1234\0 -1234"]
    result_ = codec.receive "#expected_\r"
    result_.should.eql expected_
    done!

  it 'should handle a null chunk', (done) ->
    codec.flush!
    expected = null
    result = codec.receive expected
    (result == expected).should.equal.true
    done!

describe 'the tss.decode', (_) ->
  it 'should return the decoded Sounder message', (done) ->
    given = ":123456 123456 123456 -1234?-1234 -1234"
    expected = {
      talker     : ""
      sentence   : "TSS-Sounder"
      identifier : "123456"
      depth      : 1234.56
      corr-depth : 1234.56
      heave      : -12.34
      quality    : "?"
      roll       : -12.34
      pitch      : -12.34
    }
    result = codec.decode given
    result.should.eql expected
    done!
