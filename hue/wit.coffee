hue = require './hue'

module.exports = (wit) ->
  wit.on 'lights_on', ->
    console.log "Turning lights ON"
    hue.turnOn()

  wit.on 'lights_off', ->
    console.log "Turning lights OFF"
    hue.turnOff()

  wit.on 'lights_colour', ({entities}) ->
    console.log "Turning lights to colour", entities.colour[0]
    hue.setColor entities.colour[0].metadata.rgb
