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
  req.io.emit 'message', message: "ya let's do it!"

app.io.route 'deleteCard', (req) ->
  taskName = 'deleteCard'
  pp = new peggParse config.PARSE_APP_ID, config.PARSE_MASTER_KEY
  pp.on 'message', (message) ->
    req.io.emit 'message', { taskName, message }
  pp.on 'done', (cardId, results) ->
    req.io.emit 'done', { taskName, results, message: "Success! Card #{cardId} has been obliterated. It is no more." }
  pp.on 'error', (error) ->
    console.log error.stack
    req.io.emit 'error', { taskName, error }
  console.log "delete card #{req.data}"
  pp.deleteCard req.data

app.io.route 'resetUser', (req) ->
  taskName = 'resetUser'
  pp = new peggParse config.PARSE_APP_ID, config.PARSE_MASTER_KEY
  pp.on 'message', (message) ->
    req.io.emit 'message', { taskName, message }
  pp.on 'done', (userId, results) ->
    req.io.emit 'done', { taskName, results, message: "Success! User #{userId} is fresh like spring pheasant." }
  pp.on 'error', (error) ->
    console.log error.stack
    req.io.emit 'error', { taskName, error }
  console.log "reset user #{req.data}"
  pp.resetUser req.data

app.listen app.port, ->
  console.log "Listening on " + app.port + "\nPress CTRL-C to stop server."
