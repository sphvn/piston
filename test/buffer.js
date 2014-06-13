'use strict';
var server = require("../server.js");

describe('the decoder unchunker', function () {
  it('should return the message when the chunk is the message', function (done) {
    var expected = "$HEHDT,289.97,T*12";
    var given = expected;
    var result = server.unchunker(given);
    result.should.equal(expected);
    done();
  });

  it('should return the message when the chunk contains the message', function (done) {
    var expected = "$HEHDT,289.97,T*12";
    var given = ",T*12;" + expected + ";$HEHDT,2";
    var result = server.unchunker(given);
    result.should.equal(expected);
    done();
  });

  it('should return the message from multiple chunks', function (done) {
    var expected = "$HEHDT,289.97,T*12";
    var one = ",T*12;";
    var two = "$HEHDT,289";
    var three = ".97,T*12";
    var four = ";$HEHDT,2";
    var result = server.unchunker(one);
    result = server.unchunker(two);
    result = server.unchunker(three);
    result = server.unchunker(four);
    result.should.equal(expected);
    done();
  });
});