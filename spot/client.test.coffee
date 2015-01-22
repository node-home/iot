window.socket = socket = io('http://localhost:4444/spot')

@video = video = document.getElementById("video")
@embed = embed = document.getElementById("embed")
@object = object = document.getElementById("object")
@container = container = document.getElementById("container")

###
Class enhancements
###
# Function::define = (prop, desc) ->
#   Object.defineProperty @::, prop, desc

# moduleKeywords = ['included', 'extended']

# Function::include: (obj) ->
#   throw 'include(obj) requires obj' unless obj
#   for key, value of obj:: when key not in moduleKeywords
#     @::[key] = value
#   obj.included?.apply(this)
#   this

# class Named
#   @define 'singular',
#     get: @name ? @constructor.name
#   @define 'plural',
#     get: @_plural ? @singular + 's'


class Spot
  @things: {}
  @sockets: []

  @agent = ->
    name: 'Chrome'
    version: 'Something'

  @init: ->
    Video.init()
    Audio.init()
    Location.init()
    Motion.init()
    Orientation.init()

  @addThing: (thing) =>
    if thing.unique
      @things[thing.name] = thing
    else
      @things[thing.name] ?= {}
      @things[thing.serial] = thing

  @removeThing: (thingOrName, serial) =>
    if serial
      delete @things[thingOrName][serial]
    else
      delete @things[thingOrName.constructor.name][thingOrName.serial]

  @getState: =>
    things = {}
    for name, serials of @things
      things[name] = (serial for serial of serials).sort()
    things

  @getThingState: (name, serial) ->
    @things[name][serial].getState()

class Thing
  @name: 'thing'
  @serial: 0
  @broadcastInterval: 0
  @unique: false

  constructor: ->
    @serial = @constructor.serial += 1
    @update()
    # if @broadcastInterval
    #   @interval = setInterval @update, @broadcastInterval

  # on: (intent, callback) =>
  #   spot.on "#{@constructor.name}/#{@serial}/#{intent}", callback

  # emit: (intent, entities) =>
  #   spot.emit "#{@constructor.name}/#{@serial}/#{intent}", entities

  update: =>
    Promise
      .resolve @getState()
      .then (state) =>
        console.log @constructor.name + ':update', state
        # socket.emit @constructor.name + ':update', state

  getState: ->
    error: 'Not implemented'

class Thingleton
  @autoBroadcast = true
  @state = undefined

  getState: =>
    @constructor.state

  @broadcast: (state) =>
    console.log "#{@name}:state", state ? @state
    # socket.emit "#{@name}:state", state ? @state

  @updateState: (state) =>
    console.log @name, {state}
    @state = state
    @broadcast() if @autoBroadcast

class Location extends Thingleton
  @name: 'location'

  @init: =>
    watchPosition @updateState if @autobroadcast

  @getState: ->
    new Promise navigator.geolocation.getCurrentPosition

class Orientation extends Thingleton
  @name: 'orientation'

  @init: =>
    window.addEventListener 'deviceorientation', @updateState

class Motion extends Thingleton
  @name: 'motion'

  @init: =>
    window.addEventListener 'devicemotion', @updateState


class MediaThing extends Thing
  constructor: (id) ->
    @$el = $ id
    @el = @$el[0]
    @player = @$el.mediaelementplayer()

    @history = []
    @historyIndex = -1

    super()

  play: ({src}) ->
    if src
      @player.pause()
      @player.setSrc src

    @player.play()

  pause: ->
    @player.pause()

class Audio extends MediaThing
  @init: ->
    $('audio').each ->
      new Audio this

  getState: ->
    id: @serial
    formats:
      wav: @el.canPlayType("audio/wave")
      ogg: @el.canPlayType("audio/ogg")
      mp3: @el.canPlayType("audio/mpeg")
    playing: false
    duration: @player.duration
    currentTime: @player.currentTime
    history: @history

  constructor: ->
    super()
    socket.on 'play_audio', @play
    socket.on 'pause_audio', @pause

class Video extends MediaThing
  @init: ->
    $('video').each ->
      new Video this

  getState: ->
    id: @serial
    width: @$el.width()
    height: @$el.height()
    formats:
      wav: @el.canPlayType("audio/wave")
      mp3: @el.canPlayType("audio/mpeg")
    playing: false
    duration: @player.duration
    currentTime: @player.currentTime
    history: @history

  constuctor: ->
    super()
    socket.on 'play_video', @play
    socket.on 'pause_video', @pause

console.log "Defining globals!"

@requestAudio = ->
  socket.emit 'request_audio'

@requestVideo = ->
  socket.emit 'request_video'

Spot.init()