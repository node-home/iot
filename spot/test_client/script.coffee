window.socket = socket = io('http://localhost:4444/spot')

@video = video = document.getElementById("video")
@embed = embed = document.getElementById("embed")
@object = object = document.getElementById("object")
@container = container = document.getElementById("container")

class Spot
  @things: {}
  @sockets: []

  @agent:
    name: 'Chrome'
    version: 'Something'

  @init: ->
    Video.init()
    Audio.init()
    Location.init()
    Motion.init()
    Orientation.init()

  @addThing: (thing) =>
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
    if @broadcastInterval
      @interval = setInterval @update, @broadcastInterval

  # on: (intent, callback) =>
  #   spot.on "#{@constructor.name}/#{@serial}/#{intent}", callback

  # emit: (intent, entities) =>
  #   spot.emit "#{@constructor.name}/#{@serial}/#{intent}", entities

  update: =>
    socket.emit @constructor.name + ':update', Promise.resolve @getState()

  getState: ->
    error: 'Not implemented'

class Thingleton
  @autoBroadcast = true
  @state = undefined

  getState: =>
    @constructor.state

  @broadcast: (state) =>
    socket.emit "#{@name}:state", state ? @state

  @updateState: (state) =>
    console.log @name, {state}
    @state = state
    @broadcast() if @autoBroadcast

class Location extends Thingleton
  @name: 'location'

  @init: =>
    watchPosition @updateState if @autobroadcast

  @getState: ->
    navigator.geolocation.getCurrentPosition Promise.resolve

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

  play: (src) ->
    if src
      @player.pause()
      @player.setSrc src

    @player.play()

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

    socket.on 'play_audio', ({src}) =>
      return @play src

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

    socket.on 'play_video', ({src}) =>
      return @play src

@requestAudio = ->
  socket.emit 'request_audio'

@requestVideo = ->
  socket.emit 'request_video'

Spot.init()