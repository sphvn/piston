ntp = require "./ntp.js"
mmt = require \moment
con = require \connect
dgr = require \dgram
prt = require \serialport
fig = require \figlet
srv = require \ws .Server
wss = new srv { port: 8000 }

fig "PiSTON", {font: 'Delta Corps Priest 1'}, (_, data) -> console.log data

set-decoder = (dn) ->
  return require "./decoders/#dn.js"

clients = []
disconnect = (c) ->
  i = clients.index-of c
  clients.splice(i, 1) if i != -1

codec = set-decoder "nmea"

receive-chunk = (chunk) ->
  for msg in codec.receive chunk
    obj = piston-time: mmt.utc!, raw: msg
    obj <<< codec.decode msg
    json = JSON.stringify obj
    for c in clients
      c.send json

start-serial = ->
  prt.list (err, [port]) ->
    console.log "Reading from #{port.com-name}"
    ser = new prt.SerialPort port.com-name, { baudrate : 19200 }, true
    ser.on \open -> ser.on \data, receive-chunk

start-udp = ->
  udp = new dgr.create-socket \udp4
  udp.on \message, receive-chunk
  udp.on \error (msg) -> console.log "error: #msg"
  udp.bind 40001

switch process.argv.2
  | \serial => start-serial!
  | \udp => start-udp!
  | otherwise => start-serial!

wss.on \connection (ws) ->
  clients.push ws
  ws.on \message (m) -> console.log m
  ws.on \close -> disconnect ws
  ws.on \error -> disconnect ws

# console.log "localhost      : #{mmt(new Date).format 'HH:mm:ss.SSS'}"
# ntp.get-network-time "172.23.21.255", 123, (server, stratum, time) ->
#   while server.length < 15
#     server += ' '
#   if stratum > 0
#     console.log "#server: #{(mmt time).format 'HH:mm:ss.SSS'}  stratum: #stratum"


con!use (con.static __dirname) .listen 8080