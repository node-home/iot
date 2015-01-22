request = require 'request'
events  = require 'events'
Q       = require 'q'

HOST = 'http://192.168.1.70'
APP  = 'jessethegame'

class Color
  @rgbToHsl: ({r, g, b}) ->
    r /= 255
    g /= 255
    b /= 255

    max = Math.max r, g, b
    min = Math.min r, g, b

    l = (max + min) / 2

    if max == min
      h = s = 0 # achromatic
    else
      d = max - min
      s = if l > 0.5 then d / (2 - max - min) else d / (max + min)
      switch max
        when r then h = (g - b) / d + (if g < b then 6 else 0)
        when g then h = (b - r) / d + 2
        when b then h = (r - g) / d + 4

      h /= 6

    {h, s, l}

  @rgbToHsb: (rgb) =>
    hsl = @rgbToHsl rgb
    hue: Math.floor hsl.h * 65535
    sat: Math.floor hsl.s * 255
    bri: Math.floor hsl.l * 255


class Hue extends events.EventEmitter
  @api: (method, path, options) ->
    #console.log "api", {method, path, options}

    options ||= {}
    options.method = method
    app = options.app ? APP
    options.url = "#{HOST}/api/#{app}#{path}"

    dfd = Q.defer()

    request options, (err, response, body) ->
      return dfd.reject err if err
      dfd.resolve body

    dfd
      .promise
      .then (data) ->
        #console.log "SUCCESS", options, data
        data
      .fail (data) ->
        #console.log "ERROR", options, data
        data

  @state: (state, id) =>
    path = if id? then "/lights/#{id}/state" else "/groups/0/action"

    @api 'PUT', path, json: state

  @toggle: (state, id) =>
    @state on: state

  @turnOn: (id) =>
    @toggle on, id

  @turnOff: (id) =>
    @toggle off, id

  @setColor: (rgb, id) =>
    @state Color.rgbToHsb(rgb), id

  @flipColor: (rgb, id) =>
    state = Color.rgbToHsb  rgb
    state.transitiontime = 0
    @state state, id

module.exports = Hue

