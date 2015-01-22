io = require 'socket.io-client'

wit = io.connect 'http://localhost:1337'

wit.on 'lights_off', ->
  console.log "GREAT SUCCESS", 'lights_off'

flow = require './flow'
flow.add wit

hueWit = require './hue/wit'
wireWit = require './wire/wit'

hueWit flow
wireWit flow

# RK Mode

wire = require './wire'

flow.on 'rk_mode', ->
  console.log 'rk_mode'
  wire.broadcast "Bow chicka wow wow! R Kelly mode engaged!"


# Daemons

tap = require './hue/tap'

flow.on 'hue_tap', ({from, to}) ->
  flow.emit 'rk_mode' if from == tap.oooo and to == tap.o

tap.start()

# Twitter

twitter = require './twitter/twitter'
twitter.start()

twitter.emitter.on 'mention', (tweet) ->
  splits = tweet.text.split(' ')
  wit.emit 'message', q: splits[1..splits.length - 1].join ' '
