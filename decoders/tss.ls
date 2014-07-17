{drop-while, span} = require 'prelude-ls' .Str
{length, to-array} = require '../prelude-ext.js'
{unpack} = require '../unpacker.js'
moment = require 'moment'

unpack-tss = (b, c) -> unpack.apply @, (to-array arguments) ++ [':' '\r']

buffer = ""
@buffer-size = -> length buffer
@flush = -> buffer := ""

@receive = (chunk) ->
  @flush! if @buffer-size! >= 16000
  msgs = []
  loop
    [buf, msg] = buffer `unpack-tss` chunk
    buffer := buf
    return msgs unless msg?
    msgs.push msg
    chunk := ""

@decode = (msg) ->
  talker         = ""
  sentence       = "TSS-Sounder"
  _identifier    = msg.substr 1 , 6
  _depth         = msg.substr 8 , 6
  _corr-depth    = msg.substr 15, 6
  _heave         = msg.substr 22, 5
  _quality       = msg.substr 27, 1
  _roll          = msg.substr 28, 5
  _pitch         = msg.substr 34

  { talker, sentence } <<<
    identifier : _identifier
    depth      : (parse-float _depth) / 100.0
    corr-depth : (parse-float _corr-depth) / 100.0
    heave      : (parse-float _heave) / 100.0
    quality    : _quality
    pitch      : (parse-float _pitch) / 100.0
    roll       : (parse-float _roll) / 100.0
