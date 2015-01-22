twitter = require 'twitter'
events  = require 'events'

emitter = new events.EventEmitter

TWITTER_HANDLE = '__RKT__'

twit = new twitter
  consumer_key: process.env.TWITTER_CONSUMER_KEY
  consumer_secret: process.env.TWITTER_CONSUMER_SECRET
  access_token_key: process.env.TWITTER_ACCESS_TOKEN_KEY
  access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET

start = ->
  twit.stream 'user', track: TWITTER_HANDLE, (stream) ->
    stream.on 'data', (data) ->
      console.log data
      if data.text?
        emitter.emit 'tweet', data

        [mention, text] = data.text.split ' ', 1

        if mention.toLowerCase() == '@' + TWITTER_HANDLE.toLowerCase()
          emitter.emit 'mention', data




module.exports = {start, twit, emitter}

  # Post to /wit endpoint
  # Return direct responses to sender

###

Usecases

Is <name> home?
Is <name> at home?
Is <name> in?
Is <name> in the house?
Are <name> and <name> home?
Are <name> and <name> at home?
Are <name> and <name> in?
Are <name> and <name> in the house?
Who are in?
Who are in the house?
Who are at home?

Remind <name> to <activity> <moment>
Remind <name> and <name> to <activity>
Remind us to <activity>

###
