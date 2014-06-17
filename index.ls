inf = (obj) ->
  console.log obj
  $ \.log .append "#{JSON.stringify(obj, void, 2)}<br/>"

host = if location.protocol == "file:"
       then "localhost"
       else location.hostname
@ws = new WebSocket "ws://#host:8000/"

ws.onmessage = (evt) ->
  obj = JSON.parse evt.data
  inf obj

ws.onclose = -> inf \closed
