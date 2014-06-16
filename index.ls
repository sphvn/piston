inf = (m) ->
  console.log m
  $ \div.log .append "#m<br/>"

@ws = new WebSocket "ws://localhost:8000/"
ws.onopen = ->
  msg = \connected
  inf "sent: #msg"
  ws.send msg 

ws.onmessage = (evt) ->
  recv = evt.data
  inf "recv: #{evt.data}"

ws.onclose = -> inf \closed
