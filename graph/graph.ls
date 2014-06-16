<-! $

prelude.installPrelude window

#########################################################################
# Sockets

host = if location.protocol == "file:"
       then "localhost"
       else location.hostname

connect = !->
  socket = new WebSocket "ws://#host:8000/"

  socket.onopen  = ->
    $ \.status .text \Connected

  disconnected = ->
    $ \.status .text \Disconnected
  disconnected!

  socket.onclose = ->
    disconnected!
    connect!

  socket.onmessage = (msg) ->
    obj = JSON.parse msg.data
    plot "#{obj.talker}#{obj.sentence}", obj

#########################################################################
# Chart

chart = new SmoothieChart {
  interpolation: \line
  millis-per-pixel: 30
  grid:
    fill-style: \transparent
    sharp-lines: true
    millis-per-line: 5000
    vertical-sections: 0
  horizontalLines: [
    color: \#777
    lineWidth: 1
    value: 0
  ]
}

set-range = (c, min, max) ->
  c.options.scale-smoothing = 1
  c.options.min-value = min
  c.options.max-value = max
  c.options.y-range-function = null

set-auto-range = (c) ->
  c.options.scale-smoothing = 0.3
  c.options.min-value = null
  c.options.max-value = null
  c.options.y-range-function = auto-y-range

auto-y-range = (range) ->
  if range.min < 0
    m = max (abs range.min), (abs range.max)
    m := m * 1.25
    min: -m, max: m
  else
    min: 0, max: range.max * 1.25

chart.stream-to (document.get-element-by-id \chart), 100
set-auto-range chart

do ->
  canvas = $ \#chart

  ups   = $ document .as-event-stream \mouseup .map false
  downs = canvas.as-event-stream \mousedown .map true

  mouse-down = downs .merge ups .to-property false

  mouse-position = $ document
    .as-event-stream \mousemove
    .map (e) -> x: e.client-x, y: e.client-y

  dragging = mouse-position
    .diff (dx:0, dy:0), (a, b) ->
      dx: b.x - a.x
      dy: b.y - a.y
    .filter mouse-down

  dragging.on-value (m) ->
    move-rel = m.dy / canvas.height!

    max  = chart.options.max-value ? chart.value-range.max
    min  = chart.options.min-value ? chart.value-range.min
    move = move-rel * (max - min)

    set-range chart, min + move, max + move

  canvas.dblclick -> set-auto-range chart

  zoom-out-factor   = 1.5
  zoom-in-factor    = 1 / zoom-out-factor
  zoom-out-location = null

  canvas.mousewheel (e, delta) ->
    clicks = abs delta
    zoom-in = delta > 0
    location = x: e.offset-x, y: e.offset-y

    if zoom-in
      # zoom to the cursor unless the user hasn't
      # moved the mouse since zooming out.
      y = if location != zoom-out-location then location.y else null
      do-zoom zoom-in-factor, y
    else
      zoom-out-location = location
      do-zoom zoom-out-factor

    false

  do-zoom = !(factor, y) ->
    zoom-pos-rel = if y? then zoom-pos-rel = y / canvas.height! else 0.5

    min = chart.value-range.min
    max = chart.value-range.max

    range    = max - min
    above    = range * zoom-pos-rel
    below    = range * (1 - zoom-pos-rel)
    zoom-pos = max - above

    new-above = factor * above
    new-below = factor * below
    new-min   = zoom-pos - new-below
    new-max   = zoom-pos + new-above

    set-range chart, new-min, new-max

#########################################################################

data = []

plot = !(sender, msg) -> append-plot sender, new Date(), msg

append-plot = (sender, time, obj) ->
  for x in map fix-units, find-values obj
    series = add-series sender, x.units, x.name
    series.append time, x.value

add-series = (sender, units, name) ->
  key = sender
  key += "/#name" if name?
  series = data[key]
  if not series?
    series := new TimeSeries
    color = next-color Object.keys(data).length
    chart.add-time-series series, {
      strokeStyle: color
      lineWidth: 3
    }
    $ \ul.legend .append """
    <li>
      <i class='icon-circle' style='color: #color'/>
      #{key .replace '<', '&lt;' .replace '>', '&gt;'}
    </li>
    """
    data[key] := series
    sort-li \ul.legend
  series

#########################################################################
# NG Utils

parse-float-strict = (x) ->
  if /^\-?[0-9]+(\.[0-9]+)?[ a-zA-Z]*$/.test x
  then parseFloat(x)
  else NaN

find-values = (obj) ->
  | typeof obj == \number => [{ value: obj, units: \unknown }]
  | typeof obj == \string =>
      x = parse-float-strict obj
      if isNaN x then [] else [{ value: x, units: \unknown }]
  | !(obj instanceof Object) => []
  | otherwise =>
    vs = []
    for k,v of obj
      if v?
        if v.value? and v.units?
          x = value: v.value, units: v.units
          vs ++= prefix-name k, x
        else
          vs ++= map (prefix-name k), find-values v
    vs

prefix-name = (pre, obj) -->
  | pre == \value          => obj
  | pre == \nameValuePairs => obj
  | not obj.name?          => obj with name: capitalize pre
  | _                      => obj with name: "#{capitalize pre}/#{obj.name}"

fix-units = (x) ->
  p = preferred-units[x.units]
  switch
  | p? => x with { units: p.name, value: p.convert x.value }
  | _  => x

rad2deg = (* 57.2957795)

preferred-units = {
  'rad':   { name: 'deg',   convert: rad2deg }
  'rad/s': { name: 'deg/s', convert: rad2deg }
}

capitalize = (xs) -> head xs .to-upper-case! + tail xs

#########################################################################
# Utils

next-color = (i) -> palette[i % palette.length]

palette = [
  \#336699 \#99CCFF \#999933 \#666699 \#CC9933
  \#006666 \#3399FF \#993300 \#CCCC99 \#666666
  \#FFCC66 \#6699CC \#663366 \#9999CC \#CCCCCC
  \#669999 \#CCCC66 \#CC6600 \#9999FF \#0066CC
  \#99CCCC \#999999 \#FFCC00 \#009999 \#99CC33
  \#FF9900 \#999966 \#66CCCC \#339966 \#CCCC33
]

sort-li = (selector) ->
  items = $ "#selector li" .get!
  items.sort (a,b) ->
    keyA = $ a .text!
    keyB = $ b .text!
    if (keyA < keyB) then return -1
    if (keyA > keyB) then return 1
    return 0
  ul = $ selector
  $.each items, (i, li) -> ul.append li

connect!