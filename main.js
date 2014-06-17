// Generated by LiveScript 1.2.0
(function(){
  var ntp, mmt, con, prt, udp, fig, srv, wss, clients, disconnect, nmea, ser;
  ntp = require("./ntp.js");
  mmt = require('moment');
  con = require('connect');
  prt = require('serialport').SerialPort;
  udp = require('dgram');
  fig = require('figlet');
  srv = require('ws').Server;
  wss = new srv({
    port: 8000
  });
  fig("PiSTON", {
    font: 'Delta Corps Priest 1'
  }, function(_, data){
    return console.log(data);
  });
  this.decoder = {};
  this.setDecoder = function(dn){
    this.decoder = require("./decoders/" + dn + ".js");
    return this.decoder;
  };
  clients = [];
  disconnect = function(c){
    var i;
    i = clients.indexOf(c);
    if (i !== -1) {
      return clients.splice(i, 1);
    }
  };
  nmea = this.setDecoder("nmea");
  ser = new prt("/dev/ttyUSB0", {
    baudrate: 9600,
    dataCallback: function(chunk){
      var i$, ref$, len$, msg, lresult$, obj, json, j$, ref1$, len1$, c, results$ = [];
      console.log("recv: " + chunk);
      for (i$ = 0, len$ = (ref$ = nmea.receive(chunk)).length; i$ < len$; ++i$) {
        msg = ref$[i$];
        lresult$ = [];
        obj = {
          pistonTime: mmt.utc(),
          raw: msg
        };
        import$(obj, nmea.decode(msg));
        json = JSON.stringify(obj);
        for (j$ = 0, len1$ = (ref1$ = clients).length; j$ < len1$; ++j$) {
          c = ref1$[j$];
          lresult$.push(c.send(json));
        }
        results$.push(lresult$);
      }
      return results$;
    }
  });
  ser.on('open', function(){
    console.log('open');
    return ser.write("ls\n", function(err, res){
      console.log("err: " + err);
      return console.log("res: " + res);
    });
  });
  wss.on('connection', function(ws){
    clients.push(ws);
    ws.on('message', function(m){
      return console.log(m);
    });
    ws.on('close', function(){
      return disconnect(ws);
    });
    return ws.on('error', function(){
      return disconnect(ws);
    });
  });
  con().use(con['static'](__dirname)).listen(8080);
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
