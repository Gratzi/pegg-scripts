expressio = require 'express.io'
peggParse = require './peggParse'
assets = require 'connect-assets'
bodyParser = require 'body-parser'

# Create app instance.
app = expressio()
app.http().io()

# Define Port & Environment
app.port = process.env.PORT or process.env.VMC_APP_PORT or 3000
env = process.env.NODE_ENV or 'development'

# Config module exports has `setEnvironment` function that sets app settings depending on environment.
config = require './config'
config.setEnvironment env

# body-parse application/json
app.use bodyParser.json()

# Add Connect Assets.
app.use assets()
# Set the client folder as static assets.
app.use expressio.static process.cwd() + '/client'

app.get '/', (req, res) ->
  res.render 'index'

# app.get '/scripts', (req, res) ->
#   list = require './list'
#   list.serverScripts res
#
# app.get '/choices', (req, res) ->
#   pp.getTable 'Choice', (data) =>
#     res.send data
#
# app.post '/choice', (req, res) ->
#   pp.updateRow 'Choice', req.body.id, { plug: req.body.orig, plugThumb: req.body.thumb }, (data) =>
#     res.send data

app.io.route 'ready', (req) ->
  console.log 'client is ready'
  req.io.emit 'message', "ya let's do it!"

app.io.route 'resetUser', (req) ->
  console.log "reset user #{req.data}"

  pp = new peggParse config.PARSE_APP_ID, config.PARSE_MASTER_KEY

  pp.on 'update', (message) ->
      req.io.emit 'update', message

  pp.on 'done', (userId, results) ->
      req.io.emit 'done', userId, results

  pp.on 'error', (error) ->
      console.log error.stack
      req.io.emit 'error', error

  pp.resetUser req.data

app.listen app.port, ->
  console.log "Listening on " + app.port + "\nPress CTRL-C to stop server."
