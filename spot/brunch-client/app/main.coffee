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
    Spot  .addThing this
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
  @feedType =
  @autoBroadcast = true
  @state = undefined
  @interval = 5000

  getState: =>
    @constructor.state

  @broadcast: (state) =>
    console.log "#{@name}:state", state ? @state
    # socket.emit "#{@name}:state", state ? @state

  @updateState: (state) =>
    console.log @name, {state}
    @state = state
    @broadcast() if @autoBroadcast

  @enableFeed: =>
    @_interval ?= setInterval @broadcast, @interval if @interval

  @disableFeed: =>
    clearInterval @_interval if @_interval


class Location extends Thingleton
  @name: 'location'

  @enableFeed: =>
    @_watcher = navigator.geolocation.watchPosition @updateState

  @disableFeed: =>
    navigator.geolocation.clearWatch @_watcher if @_watcher

  @getState: ->
    new Promise navigator.geolocation.getCurrentPosition

class Orientation extends Thingleton
  @name: 'orientation'

  @enableFeed: =>
    return if @feeding
    @feeding = true
    window.addEventListener 'deviceorientation', @updateState

  @disableFeed: =>
    return unless @feeding
    window.removeEventListener 'deviceorientation', @updateState
    @feeding = false

class Motion extends Thingleton
  @name: 'motion'

  @enableFeed: =>
    return if @feeding
    @feeding = true
    window.addEventListener 'devicemotion', @updateState

  @disableFeed: =>
    return unless @feeding
    window.removeEventListener 'devicemotion', @updateState
    @feeding = false


class MediaThing extends Thing
  constructor: (id) ->
    @$el = $ id
    @el = @$el[0]
    @player = @el

    @history = []
    @historyIndex = -1

    for intent, callback of @intents
      socket.on intent, callback.bind(this)

    super()

  play: ({src}) ->
    console.log @constructor.name, 'play', {src}
    if src
      @player.pause()
      @player.src = src

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

  intents:
    'play_audio': ({title, source}) ->
      @play source[0]

    'pause_audio': (entities) ->
      @player.pause


class Video extends MediaThing
  @init: ->
    $('video').each ->
      console.log "EACH", arguments
      new Video this

  getState: ->
    id: @serial
    width: @$el.width()
    height: @$el.height()
    formats:
      wav: @el.canPlayType("audio/wave")
      mp3: @el.canPlayType("audio/mpeg")
    playing: false
    duration: @player?.duration
    currentTime: @player?.currentTime
    history: @history

  intents:
    'play_video': ({title, source}) ->
      @play source[0]

    'pause_video': (entities) ->
      @player.pause


console.log "Defining globals!"

@requestAudio = ->
  console.log 'request_audio'
  socket.emit 'request_audio'

@requestVideo = ->
  console.log 'request_video'
  socket.emit 'request_video'

Spot.init()

window.Spot = Spot