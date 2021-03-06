// Generated by LiveScript 1.3.1
(function(){
  var inf, host;
  inf = function(obj){
    console.log(obj);
    return $('.log').append(JSON.stringify(obj, void 8, 2) + "<br/>");
  };
  host = location.protocol === "file:"
    ? "localhost"
    : location.hostname;
  this.ws = new WebSocket("ws://" + host + ":8000/");
  ws.onmessage = function(evt){
    var obj;
    obj = JSON.parse(evt.data);
    return inf(obj);
  };
  ws.onclose = function(){
    return inf('closed');
  };
}).call(this);
