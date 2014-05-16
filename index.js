var ws = new WebSocket("ws://localhost:8000/");
 ws.onopen = function()
 {
    var msg = "message";
    console.log("send: " + msg)
    ws.send(msg);
 };
 ws.onmessage = function (evt) 
 { 
    var received_msg = evt.data;
    console.log("recv: " + evt.data)
 };
 ws.onclose = function()
 { 
    console.log("closed connection...")
 };
