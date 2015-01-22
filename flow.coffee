events = require 'events'

class Flow
  constructor: ->
    @emitters = []

    @emitter = new events.EventEmitter

    @add @emitter

  add: (emitter) =>
    @emitters.push emitter

  on: (args...) =>
    emitter.on args... for emitter in @emitters

  emit: (args...) =>
    @emitter.emit args...

module.exports = new Flow
