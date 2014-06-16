{drop-while, take-while, span} = require 'prelude-ls' .Str
{drop, floor} = require 'prelude-ls'
moment = require 'moment'

length = (.length)
exspan = (c, xs) ->
  [x, y] = span (!= c), xs
  [x, drop (length c), y]

buffer = ""
@buffer-size = -> length buffer
@flush = -> buffer := ""

@receive = (chunk) ->
  @flush! if @buffer-size! > 16000
  msgs = []
  loop
    [buf, msg] = unpack buffer, chunk
    buffer := buf
    return msgs unless msg?
    msgs.push msg
    chunk := ""

unpack = (buf, chunk) ->
  _buf = drop-while (!= "$"), buf + chunk
  return [_buf, null] if (_buf.index-of "\r") == -1
  
  [msg, _buf] = span (!= "\r"), _buf
  switch
  | msg[0] == "$" => [_buf, msg]
  | otherwise     => [_buf, null]


@decode = (msg) ->
  _msg = drop 1 msg
  [_msg, checksum] = exspan '*' _msg
  return null if invalid checksum, _msg
  [prefix,    _msg]     = exspan ',' _msg
  talker   = prefix.substr(0, 2)
  sentence = prefix.substr(2)
  parts    = _msg.split(",")

  decode = decoders[sentence.to-upper-case!]
  { talker, sentence } <<< decode?.apply(this, parts)
    

decoders =
  HDT: (heading, type) ->
    heading: parse-float heading
    heading-type: type

  HDM: (heading, type) ->
    heading: parse-float heading
    heading-type: type

  VTG: (cog-t, t, cog-m, m, sog-kn, n, sog-kph, k, mode) ->
    cog:
      true: parse-float cog-t
      magnetic: parse-float cog-m
    sog:
      knots: parse-float sog-kn
      kph: parse-float sog-kph
    mode:
      code: mode
      desc: vtg-mode mode

  GGA: (time, lat, lath, lon, lonh, quality, sats, hdop, alt, alt-u, gsep, gsep-u, age, refid) ->
    q = parse-int quality
    time: moment.utc time, "HHmmss.SS"
    wgs84:
      lat: parse-ddmm lat, lath
      lon: parse-ddmm lon, lonh
      elh: parse-float(alt) + parse-float(gsep)
    quality:
      code: q
      desc: gnss-mode q
    satellites: parse-int sats
    hdop: parse-float hdop
    correction-age: parse-int age
    reference-station: parse-int refid

vtg-mode = (m) -> switch m
  | \A => "Autonomous"
  | \D => "Differential"
  | \E => "Dead Reckoning"
  | \M => "Manual Input"
  | \S => "Simulator"
  | \N => "Not Valid"
  | otherwise => "Unknown"

gnss-mode = (m) -> switch m
  | 0 => "Not Valid"
  | 1 => "Standalone"
  | 2 => "Differential"
  | 3 => "Precise"
  | 4 => "Kinematic Fixed"
  | 5 => "Kinematic Float"
  | 6 => "Dead Reckoning"
  | 7 => "Manual Input"
  | 8 => "Simulator"
  | 9 => "Kinematic Float GPS/Glonass"
  | otherwise => "Unknown"


parse-ddmm = (str, hem) ->
  num = parse-float str
  int-degs = floor(num / 100.0)
  dec-mins = num - int-degs * 100
  dec-degs = int-degs + dec-mins / 60.0
  return if /^[ws]$/i.test hem
         then -dec-degs
         else  dec-degs


invalid = (cs, msg) ->
  chk = (checksum msg).to-lower-case!
  chk != cs.to-lower-case!

checksum = (xs) ->
  x = 0
  for i from 0 to xs.length - 1
    x = x .^. xs.char-code-at i

  hex = Number x .to-string 16 .to-upper-case!
  if hex.length < 2
    (\00 + hex).slice -2
  else
    hex
