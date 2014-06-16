// Generated by LiveScript 1.2.0
(function(){
  var inf;
  inf = function(m){
    console.log(m);
    return $('div.log').append(m + "<br/>");
  };
  this.ws = new WebSocket("ws://localhost:8000/");
  ws.onopen = function(){
    var msg;
    msg = 'connected';
    inf("sent: " + msg);
    return ws.send(msg);
  };
  ws.onmessage = function(evt){
    var recv;
    recv = evt.data;
    return inf("recv: " + evt.data);
  };
  ws.onclose = function(){
    return inf('closed');
  };
}).call(this);
