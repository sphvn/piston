con = require \connect
prt = require \serialport .SerialPort
srv = require \ws .Server
wss = new srv { port: 8000 }
{drop-while, take-while} = require 'prelude-ls' .Str


d = {}
set-decoder = (dn) -> d = require "./decoders/" + dn

buffer = ""
@unchunker = (chunk) ->
  buffer += chunk
  buffer  := drop-while (!= "$"), buffer
  message = take-while (!= ";"), buffer
  if (message.length >= 1)
    buffer := drop-while (!= ";"), buffer
    message

ser = new prt "/dev/tty.usbmodem1d11", { baudrate : 9600 }, false
ser.on \data (chunk) -> unchunker chunk
ser.on \error (msg) -> console.log "error: #msg"

wss.on \connection (ws) -> ws.send \connected

con!use (con.static __dirname) .listen 8080
