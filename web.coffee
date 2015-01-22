koa = require 'koa'
app = koa()

app.use *(next) ->
  start = new Date
  yield next
  ms = new Date - start
  @set 'X-Response-Time', ms + 'ms'

# logger

app.use *(next) ->
  start = new Date
  yield next
  ms = new Date - start
  console.log '%s %s - %s', @method, @url, ms

# response

app.use *() ->
  @body = 'Hello World'

app.listen 3000

