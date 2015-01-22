spot = require './spot'
geo  = require './geo'

spot.emitter.on 'spot', (_spot) ->
  id = _spot.socket.id
  console.log "spot", id

  location = new geo.Geo id

  location.socket.on 'spot:geos', (args...) ->
    # console.log 'spot:geos', args
    console.log '.'

  location.onUpdate (news, olds) ->
    console.log {news, olds}

  _spot.on 'request_audio', ->
    console.log 'request_audio'
    _spot.emit 'play_audio',
      title: "Horse"
      tag: ['nsfw', 'nsfl', 'private', 'important']
      source: [
        {type: 'audio/mpeg', src: 'http://www.w3schools.com/html/horse.mpeg'}
        {type: 'audio/ogg',  src: 'http://www.w3schools.com/html/horse.ogg'}
        {type: 'audio/wave', src: 'http://www.w3schools.com/html/horse.wav'}
      ]

  _spot.on 'request_video', ->
    console.log 'request_video'
    _spot.emit 'play_video',
      title: "Title"
      tag: ['nsfw', 'nsfl', 'private', 'important']
      source: [
        {type: 'video/mp4', src: 'http://www.w3schools.com/html/movie.mp4'}
        {type: 'video/ogg', src: 'http://www.w3schools.com/html/movie.ogg'}
        {type: 'video/webm', src: 'http://www.w3schools.com/html/movie.webm'}
        {type: 'application/x-shockwave-flash', src: ''}
      ]


