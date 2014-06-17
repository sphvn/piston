ntp = require "./ntp.js"
mmt = require \moment
con = require \connect
prt = require \serialport
udp = require \dgram
fig = require \figlet
srv = require \ws .Server
wss = new srv { port: 8000 }

fig "PiSTON", {font: 'Delta Corps Priest 1'}, (_, data) -> console.log data

@decoder = {}
@set-decoder = (dn) ->
  @decoder := require "./decoders/#dn.js"
  return @decoder

clients = []
disconnect = (c) ->
  i = clients.index-of c
  clients.splice(i, 1) if i != -1

nmea = @set-decoder "nmea"

prt.list (err, [port]) ->
  console.log "Reading from #{port.com-name}"
  ser = new prt.SerialPort port.com-name, { baudrate : 9600 }, true
  ser.on \open ->
    ser.on \data, (chunk) ->
      for msg in nmea.receive chunk
        obj = piston-time: mmt.utc!, raw: msg
        obj <<< nmea.decode msg
        json = JSON.stringify obj
        for c in clients
          c.send json

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