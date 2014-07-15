// Generated by LiveScript 1.2.0
(function(){
  var ref$, dropWhile, span, unpack, moment, length, toArray, unpackKongsberg, buffer;
  ref$ = require('prelude-ls').Str, dropWhile = ref$.dropWhile, span = ref$.span;
  unpack = require('../unpacker.js').unpack;
  moment = require('moment');
  length = function(it){
    return it.length;
  };
  toArray = function(x){
    return Array.prototype.slice.call(x);
  };
  unpackKongsberg = function(b, c){
    return unpack.apply(this, toArray(arguments).concat(['D', '\r']));
  };
  buffer = "";
  this.bufferSize = function(){
    return length(buffer);
  };
  this.flush = function(){
    return buffer = "";
  };
  this.receive = function(chunk){
    var msgs, ref$, buf, msg;
    if (this.bufferSize() >= 16000) {
      this.flush();
    }
    msgs = [];
    for (;;) {
      ref$ = unpackKongsberg(buffer, chunk), buf = ref$[0], msg = ref$[1];
      buffer = buf;
      if (msg == null) {
        return msgs;
      }
      msgs.push(msg);
      chunk = "";
    }
  };
  this.decode = function(msg){
    var talker, sentence, parts;
    talker = "";
    sentence = "Simrad EA ASCII";
    parts = msg.split(',');
    return {
      talker: talker,
      sentence: sentence,
      time: moment(parts[1], "HHmmssSS"),
      channel: parseInt(parts[0].substr(1)),
      depth: parseFloat(parts[2]),
      backscatter: parseFloat(parts[3]),
      transducer: parseInt(parts[4]),
      slope: parseInt(parts[5]),
      frequency: parseInt(parts[6]),
      draft: parseFloat(parts[7]),
      speedOfSound: parseFloat(parts[8])
    };
  };
}).call(this);
