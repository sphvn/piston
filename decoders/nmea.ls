{drop-while, take-while, span} = require 'prelude-ls' .Str
{drop, floor, split-at} = require 'prelude-ls'
{unpack} = require '../unpacker.js'
moment = require 'moment'

length = (.length)
to-array = (x) -> Array.prototype.slice.call(x)
unpack-nmea = (b, c) -> unpack.apply this, (to-array arguments) ++ ['$' '\r']
exspan = (c, xs) ->
  [x, y] = span (!= c), xs
  [x, drop (length c), y]

buffer = ""
@buffer-size = -> length buffer
@flush = -> buffer := ""

@receive = (chunk) ->
  @flush! if @buffer-size! >= 16000
  msgs = []
  loop
    [buf, msg] = buffer `unpack-nmea` chunk
    buffer := buf
    return msgs unless msg?
    msgs.push msg
    chunk := ""

@decode = (msg) ->
  _msg = drop 1 msg
  [_msg, checksum] = exspan '*' _msg
  return null if invalid checksum, _msg
  [prefix, _msg] = exspan ',' _msg
  talker         = prefix.substr(0, 2)
  sentence       = prefix.substr(2)
  parts          = _msg.split(",")

  decode = decoders[sentence.to-upper-case!]
  { talker, sentence } <<< decode?.apply(this, parts)
    

decoders =
  APB: (status1, status2, xte, xte-dir, xte-unit, arrive-circ, arrive-perp, origin-brg, origin-brg-h, wpt-id, present-brg, present-brg-h, steer-heading, steer-heading-h, mode) ->
    status: status1
    xte: 
      magnitude: parse-float xte
      dir-to-steer: xte-dir
      units: xte-unit
    arrival-circle-entered: arrive-circ
    perp-passed-wpt: arrive-perp
    bearing:
      origin-to-destination: parse-float origin-brg
      present-to-destination: parse-float present-brg
    dest-wpt-id: wpt-id
    heading-to-steer: parse-float heading-to-steer
    mode: mode

  DBS: (depth-feet, fe, depth-metres, m, depth-fathoms, fa) ->
    depth:
      feet: parse-float depth-feet
      metres: parse-float depth-metres
      fathoms: parse-float depth-fathoms

  DBT: (depth-feet, fe, depth-metres, m, depth-fathoms, fa) ->
    depth:
      feet: parse-float depth-feet
      metres: parse-float depth-metres
      fathoms: parse-float depth-fathoms

  DPT: (rel-depth, offset, range-scale) ->
    rel-depth: parse-float rel-depth
    offset: parse-float offset
    #range-scale: parse-float range-scale

  GGA: (time, lat, lath, lon, lonh, quality, sats, hdop, alt, alt-u, gsep, gsep-u, age, refid) ->
    q = parse-int quality
    time: moment.utc time, "HHmmss.SS"
    wgs84:
      lat: parse-ddmm lat, lath
      lon: parse-ddmm lon, lonh
      elh: (parse-float alt) + (parse-float gsep)
    quality:
      code: q
      desc: gnss-mode q
    satellites: parse-int sats
    hdop: parse-float hdop
    correction-age: parse-int age
    reference-station: parse-int refid

  GSA: (m1, m2, ...sats) ->
    mode        : gsa-mode m1
    calc        : parse-int m2
    calc-desc   : gsa-calc parse-int m2
    pdop        : parse-float sats[12]
    hdop        : parse-float sats[13]
    vdop        : parse-float sats[14]
    sats        : (
                    for i from 0 to sats.length - 4
                      sats[i] unless sats[i] == ''
                    )

  GST: (time, rms, smaj-sd, smin-sd, ori, lat-sd, lon-sd, elh-sd) ->
    time: moment.utc time, "HHmmss.SS"
    rms: parse-float rms
    standard-deviation:
      semi-major: parse-float smaj-sd
      semi-minor: parse-float smin-sd
      lat: parse-float lat-sd
      lon: parse-float lon-sd
      elh: parse-float elh-sd
    orientation: parse-float ori

  GSV: (n, i, t, ...sats) ->
    ss = multi-split 4, sats
    total-parts : parse-int n
    part-id     : parse-int i
    total-sats  : parse-int t
    sats        : {[ (parse-int s.0), { elevation : (parse-int s.1)
                                      , azimuth   : (parse-int s.2)
                                      , snr       : (parse-int s.3) }] for s in ss }

  HDG: (heading, deviation, dev-hem, variation, var-hem) ->
    _dev = parse-float deviation
    _dev if /^[w]$/i.test dev-hem
         then -dev
         else  dev
    _var = parse-float variation
    _var if /^[w]$/i.test var-hem
         then -_var
         else  _var
    heading: parse-float heading
    magnetic-dev: _dev
    magnetic-var: _var

  HDM: (heading, type) ->
    heading: parse-float heading
    heading-type: type

  HDT: (heading, type) ->
    heading: parse-float heading
    heading-type: type

  MTW: (temperature, unit) ->
    temperature: parse-float temperature
    unit: unit

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

  XDR: (...data) ->
    ss = multi-split 4, data
    data : {[ s.3, { type  : (xdr-type s.0)
                     , value : (parse-float(s.1) || 0.0)
                     , unit  : ((xdr-unit s.0, s.2))}] for s in ss }

  ZDA: (time, day, month, year, tz-h, tz-m) ->
    timedate = "#year-#month-#day #time"
    time: moment.utc timedate, "yyyy-MM-DD HHmmss.SS"
    timezone:
      hours: parse-int tz-h
      minutes: parse-int tz-m


multi-split = (n, xs) ->
  go = (acc, xs) ->
    | xs.length == 0 => acc
    | _              =>
        [ys, zs] = split-at n, xs
        go (acc ++ [ys]), zs
  go [], xs

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

gsa-mode = (m) -> switch m
  | \A => "Automatic"
  | \M => "Manual"
  | otherwise => "Unknown"

gsa-calc = (m) -> switch m
  | 1 => "Fix not available"
  | 2 => "2D"
  | 3 => "3D"
  | otherwise => "Unknown"

vtg-mode = (m) -> switch m
  | \A => "Autonomous"
  | \D => "Differential"
  | \E => "Dead Reckoning"
  | \M => "Manual Input"
  | \S => "Simulator"
  | \N => "Not Valid"
  | otherwise => "Unknown"

xdr-type = (t) -> switch t
  | \C => "Temperature"
  | \A => "Angular Displacement"
  | \D => "Linear Displacement"
  | \F => "Frequency"
  | \N => "Force"
  | \P => "Pressure"
  | \R => "Flow Rate"
  | \T => "Tachometer"
  | \H => "Humidity"
  | \V => "Volume"
  | \G => "Generic"
  | \I => "Current"
  | \U => "Voltage"
  | \S => "Switch or Valve"
  | \L => "Salinity"
  | otherwise => "Unknown"

xdr-unit = (t, u) -> switch u
  | \C => "Degrees Celsius"
  | \D => "Degrees"
  | \M => (switch t
    | \D => "Metres"
    | otherwise => "Cubic Metres"
    )
  | \H => "Hertz"
  | \N => "Newton"
  | \B => "Bars"
  | \P => (switch t
    | \P => "Pascal"
    | otherwise => "Percent"
    )
  | \L => "Litres/second"
  | \R => "RPM"
  | " " => "None"
  | \A => "Amperes"
  | \V => "Volts"
  | \S => "PPT"
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
