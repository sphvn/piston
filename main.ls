ntp = require "./ntp.js"
mmt = require \moment
con = require \connect
prt = require \serialport .SerialPort
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

#    sats        : {[ (parse-int s.0), { elevation : (parse-int s.1)
#                                      , azimuth   : (parse-int s.2), noise: (parse-int s.3) }] for s in ss }

#ser = new prt "/dev/tty.usbmodem1d11", { baudrate : 9600 }, false
#ser.on \data (chunk) ->
ser = new udp.create-socket \udp4
ser.on \message !(chunk, sender) ->
  for msg in nmea.receive chunk
    obj = piston-time: mmt.utc!, raw: msg
    obj <<< nmea.decode msg
    json = JSON.stringify obj
    for c in clients
      c.send json

ser.on \error (msg) -> console.log "error: #msg"
ser.bind 40001

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