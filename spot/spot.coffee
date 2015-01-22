# This module models spots. A spot is a single device with
# identified by its socket id. The device exposes its
# peripherals and features through the socket.
# The spot can be a browser window, a service on a raspberry pi,
# a native app; anything that can connect via a socket.
# The peripheral information is stored in redis and can be used by
# other processes. The spot module provides convenient ways
# to pass around intents and entities to peripherals meeting
# specific conditions.
#
# TODO multiple instances of peripherals per spot
# /spots/:spot_id/:peripheral/:peripheral_id
# /spots/1/videos/1
# /spots/1/location
# /spots/1/orientation
# /spots/1/connection
redis = require 'then-redis'

port = process.env.PORT ? 4444
io    = require('socket.io') port
console.log 'spot.socket on', port


io.on 'spot:geos', (args...) ->
  console.log "ALL THE spot:geos", args

{EventEmitter} = require 'events'

emitter = new EventEmitter

class Redisable
  _redis = redis.createClient()

  constructor: (@key, @expiry) ->
    @redis = _redis

class Hash extends Redisable
  getall: (key) =>
    @redis.hgetall key

  get: (field) =>
    @redis.hget @key, field

  set: (field, value) =>
    @redis.multi()
    @redis.hset @key, field, value
    @redis.expire @expiry if @expiry
    @redis.exec()

  del: (field) =>
    @redis.hdel @key, field

  mset: (hash) =>
    arr = []

    for field, value of hash
      arr.push field
      arr.push value

    @redis.multi()
    @redis.hmset @key, arr
    @redis.expire @expiry if @expiry
    @redis.exec()


class Set extends Redisable
  add: (member) =>
    @redis.sadd @key, member

  rem: (member) =>
    @redis.srem @key, member

  ismember: (member) =>
    @redis.sismember @key, member

  has: (member) =>
    @isMember member

  @union: (keys...) =>
    @redis.sunion keys...

  @intersect: (keys...) =>
    @redis.sintersect keys...


all = {}
online = {}

peripherals = [
  'mics'
  'sockets'
  'screens'
  'speakers'
  'geos'
  'compasses'
  'gyros'
  'readers'
]

for name in peripherals
  all[name] = new Set "spot:#{name}"
  online[name] = new Set "spot:#{name}"

io.of '/spot'
  .on 'connection', (socket) ->

    user = new Set "spot:users:anonymous"

    emitter.emit 'spot', new Spot socket

    one = {}

    for name in peripherals
      one[name] = new Hash "spot:#{name}:#{socket.id}"

    all.sockets.add socket.id
    online.sockets.add socket.id

    socket.on 'disconnect', ->
      console.log 'spot:disconnect', socket.id

      for name in peripherals
        online[name].rem socket.id

      user?.rem socket.id

    for name in peripherals
      do (name) ->
        console.log {name}
        socket.on "spot:#{name}", (message) ->
          console.log "spot:#{name}", message
          emitter.emit "spot:#{name}:#{socket.id}", message
        socket.on "#{name}:update", (update) ->
          console.log "#{name}:update", update
          one[name].mset update
        socket.on "#{name}:connect", ->
          console.log "#{name}:connect"
          online[name].add socket.id
        socket.on "#{name}:disconnect", ->
          console.log "#{name}:disconnect"
          online[name].rem socket.id

    socket.on 'users:connect', ({token}) ->
      console.log 'users:connect', {token}

      User
        .findByToken(token)
        .then ({id}) ->
          user.rem socket.id
          user = new Set "spot:users:#{id}"
          user.add socket.id
          online.users.add id
        .fail (e) ->
          console.log "MISCONNECT", e
          socket.emit 'misconnect'

for name in peripherals
  do (name) ->
    io.of '/spot/' + name
      .on 'connection', (socket) ->
        console.log {name}
        socket.on "spot:#{name}", (message) ->
          console.log "spot:#{name}", message
          emitter.emit "spot:#{name}:#{socket.id}", message
        socket.on "#{name}:update", (update) ->
          console.log "#{name}:update", update
          one[name].mset update
        socket.on "#{name}:connect", ->
          console.log "#{name}:connect"
          online[name].add socket.id
        socket.on "#{name}:disconnect", ->
          console.log "#{name}:disconnect"
          online[name].rem socket.id

class Peripheral
  @slug: 'peripherals'

  constructor: (id) ->
    @hash = {}
    # @socket ?= io.sockets.sockets[id]
    @socket = io.sockets.connected[id]

    @socket.on 'spot:update', ->
      console.log 'DAT spot:update THO'

    @socket.on 'foo', ->
      console.log 'DAT FOO THO'

    @channel = "spot:#{@constructor.slug}"
    @key = "#{@channel}:#{id}"

    @db = new Hash @key
    @db
      .getall()
      .then (hash) =>
        @hash = hash

  onUpdate: (callback) =>
    @on 'update', (newHash) =>
      Hash.redis.multi()
      Hash.redis.hgetall @key
      Hash.redis.hmset @key, newHash
      Hash.redis.exec (oldHash) ->
        callback newHash, oldHash

  # TODO These two are awful, please find something more elegant
  on: (_intent, callback) =>
    console.log "ON", {_intent}, @channel
    @socket.on @channel, ({intent, entities}) =>
      console.log "ON", {intent}
      callback entities if _intent == intent

  emit: (intent, entities) =>
    @socket.emit @channel, {intent, entities}


class Spot
  constructor: (@socketOrId) ->
    @socket = if @socketOrId.id? then @socketOrId else io.sockets.sockets[@socketOrId]

  on: (intent, callback) ->
    @socket.on intent, callback

  emit: (intent, entities) ->
    @socket.emit intent, entities

  peripheral: (name) ->
    online[name]
      .ismember @id
      .then (ismember) =>
        throw "No #{name} online for #{@id}" unless ismember
        new classes[name] @id

class User
  constructor: (id) ->
    @key = "spot:users:#{id}"

  emit: (peripheral, intent, entities) ->

  getOnlineMembers: (peripheral) =>
    Set.union @key, online[peripheral].key

  getAnyPeripheral: (name) =>
    @getMembers name
      .intersect (members...) ->
        throw "No #{name}" unless members.length

        new classes[name] members[0]

  getAllPeripherals: (name) =>
    @getMembers name
      .intersect (members...) ->
        new classes[name] member for member in members


# spot =
#   id:
#   online: yes/no
#   last_updated: Date
#   created_at: Date
#   reader:
#     markdown:
#     clatter:
#     flicker:
#   audio:
#     volume:
#     playing:
#     enabled:
#     tts:
#   image:
#     enabled:
#     taken:
#   video:
#     enabled:
#     playing:
#   mic:
#     enabled:
#     recording:
#   internet:
#     enabled:
#     adapter: 'wifi/3g/4g'
#     cost: '$/MB'
#     speed: 'MB/s'
#   screen:
#     video: yes/no
#     width: 0
#     height: 0
#     orientation: 'landscape/portrait/square'
#   geo:
#     lat:
#     lng:
#     speed:
#     direction:
#   compass:
#     direction:
#   gyro:
#     orientation:

module.exports = {Peripheral, emitter, Spot}