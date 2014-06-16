'use strict';
var server = require("../server.js");
server.setDecoder("nmea");

describe('the decoder unchunker', function () {
  it('should return the message when the chunk is the message', function (done) {
    var expected = "$HEHDT,289.97,T*12";
    var given = expected + "\r";
    server.decoder.flush();
    var result = server.decoder.receive(given);
    result.should.equal(expected);
    done();
  });

  it('should return the message when the chunk contains the message', function (done) {
    var expected = "$HEHDT,289.97,T*12";
    var given = ",T*12\r" + expected + "\r$HEHDT,2";
    server.decoder.flush();
    var result = server.decoder.receive(given);
    result.should.equal(expected);
    done();
  });

  it('should return the message from multiple chunks', function (done) {
    var expected = "$HEHDT,289.97,T*12";
    var one = ",T*12\r";
    var two = "$HEHDT,289";
    var three = ".97,T*12";
    var four = "\r$HEHDT,2";
    server.decoder.flush();
    var result = server.decoder.receive(one);
    result = server.decoder.receive(two);
    result = server.decoder.receive(three);
    result = server.decoder.receive(four);
    result.should.equal(expected);
    done();
  });

  it('should flush the buffer if it reaches 16k', function (done) {
    server.decoder.flush();
    for (var i = 16000 - 1; i >= 0; i--) {
      var m = server.decoder.receive("h");
    };
    var result = server.decoder.bufferSize;
    result.should.equal(0)
    done();
  });

  it('should handle a null character in chunk', function (done) {
    server.decoder.flush();
    var expected1 = "$HEHDT,289.97,T*12";
    var result1 = server.decoder.receive(expected1 + "\rA\0Z");
    result1.should.equal(expected1)
    
    server.decoder.flush();
    var expected2 = "$HEHDT,289.97,\0T*12";
    var result2 = server.decoder.receive(expected2 + "\r");
    result2.should.equal(expected2)
    done();
  });

  it('should handle a null chunk', function (done) {
    server.decoder.flush();
    var expected = null;
    var result = server.decoder.receive(expected);
    (result === null).should.be.true
    done();
  });
});