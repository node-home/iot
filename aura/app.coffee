# Aura!
http   = require 'http'
sockjs = require 'sockjs'

hue    = require '../hue/hue'

serial = 0

ws = sockjs.createServer()
ws.on 'connection', (conn) ->
  id = serial += 1

  conn.on 'data', ({uid, distance}) ->
    conn.write(message)

  conn.on 'close', ->
    console.log 'connection', id

server = http.createServer()
port   = process.env.PORT || 5000

echo.installHandlers server, prefix: '/echo'

server.listen port, '0.0.0.0', ->
  console.log "Listening on", port
