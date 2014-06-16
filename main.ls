con = require \connect
prt = require \serialport .SerialPort
srv = require \ws .Server
wss = new srv { port: 8000 }

@decoder = {}
@set-decoder = (dn) -> @decoder := require "./decoders/#dn.js" 

ser = new prt "/dev/tty.usbmodem1d11", { baudrate : 9600 }, false
ser.on \data (chunk) ->
  msg = decoder.receive chunk
  obj = decoder.decode msg if msg?
ser.on \error (msg) -> console.log "error: #msg"

wss.on \connection (ws) ->
  ws.send \connected
  ws.on \message (m) -> console.log m

con!use (con.static __dirname) .listen 8080