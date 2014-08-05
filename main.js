// Generated by LiveScript 1.2.0
(function(){
  var ntp, mmt, con, dgr, prt, fig, srv, wsServer, args, length, setDecoder, clients, disconnect, codec, receiveChunk, startCom, startUdp;
  ntp = require("./ntp.js");
  mmt = require('moment');
  con = require('connect');
  dgr = require('dgram');
  prt = require('serialport');
  fig = require('figlet');
  srv = require('ws').Server;
  wsServer = new srv({
    port: 8000
  });
  args = process.argv;
  length = function(it){
    return it.length;
  };
  fig("PiSTON", {
    font: 'Delta Corps Priest 1'
  }, function(_, data){
    return console.log(data);
  });
  if (length(args) <= 2) {
    console.log("using defaults");
  }
  setDecoder = function(dn){
    var js;
    js = "./decoders/" + dn + ".js";
    console.log(js);
    return require(js);
  };
  clients = [];
  disconnect = function(c){
    var i;
    i = clients.indexOf(c);
    if (i !== -1) {
      return clients.splice(i, 1);
    }
  };
  codec = setDecoder((function(){
    switch (args[3]) {
    case 'nmea':
      return 'nmea';
    case 'tss':
      return 'tss';
    case 'kongsberg-ea':
      return 'kongsberg-ea';
    default:
      return "nmea";
    }
  }()));
  receiveChunk = function(chunk){
    var i$, ref$, len$, msg, lresult$, obj, json, j$, ref1$, len1$, c, results$ = [];
    for (i$ = 0, len$ = (ref$ = codec.receive(chunk)).length; i$ < len$; ++i$) {
      msg = ref$[i$];
      lresult$ = [];
      obj = {
        pistonTime: mmt.utc(),
        raw: msg
      };
      import$(obj, codec.decode(msg));
      json = JSON.stringify(obj);
      for (j$ = 0, len1$ = (ref1$ = client).length; j$ < len1$; ++j$) {
        c = ref1$[j$];
        lresult$.push(c.send(json));
      }
      results$.push(lresult$);
    }
    return results$;
  };
  startCom = function(){
    return prt.list(function(err, arg$){
      var port, ser;
      port = arg$[0];
      console.log("com:" + port.comName);
      ser = new prt.SerialPort(port.comName, {
        baudrate: 19200
      }, true);
      return ser.on('open', function(){
        return ser.on('data', receiveChunk);
      });
    });
  };
  startUdp = function(port){
    var udp;
    console.log("udp:" + port);
    udp = new dgr.createSocket('udp4');
    udp.on('message', receiveChunk);
    udp.on('error', function(msg){
      return console.log("error: " + msg);
    });
    return udp.bind(port);
  };
  switch (args[4]) {
  case 'com':
    startCom();
    break;
  case 'udp':
    startUdp(args[5]) || 40001;
    break;
  default:
    startCom();
  }
  wsServer.on('connection', function(ws){
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
  con().use(con['static'](__dirname)).listen(args[2]) || 8080;
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
