inf = (obj) ->
  console.log obj
  $ \.log .append "#{JSON.stringify(obj, void, 2)}<br/>"

@ws = new WebSocket "ws://localhost:8000/"

ws.onmessage = (evt) ->
  obj = JSON.parse evt.data
  inf obj

ws.onclose = -> inf \closed
