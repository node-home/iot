flow = require '../flow'
hue  = require './hue'

APP                = 'AmQpVcrZyhci9gkf'
SENSOR_NAME        = 'Hallway'
SENSOR_KEY         = 'buttonevent'
TAP_EVENT          = 'hue_tap'

POLL_INTERVAL      = 1000
RECONNECT_INTERVAL = 30000

running = false
current = undefined

getSensor = (name) ->
  (sensors) ->
    return sensor for index, sensor of sensors when sensor.name == name
    throw "Hue sensor #{name} not found"

getSensorState = (key) ->
  (sensor) ->
    sensor.state?[key]

emitStateChange = (event) ->
  (state) ->
    flow.emit event, from: current, to: state if current? and state != current
    state

iterate = (delay) ->
  (state) ->
    current = state
    setTimeout poll, delay if running

reconnect = (delay) ->
  (reason) ->
    current = undefined
    setTimeout poll, delay if running

poll = ->
  hue
    .api 'get', '/sensors', app: APP
    .then JSON.parse
    .then getSensor SENSOR_NAME
    .then getSensorState SENSOR_KEY
    .then emitStateChange TAP_EVENT
    .then iterate POLL_INTERVAL
    .fail reconnect RECONNECT_INTERVAL

module.exports =
  o:    34
  oo:   16
  ooo:  17
  oooo: 18

  start: ->
    running = true
    poll()

  stop: ->
    running = false

