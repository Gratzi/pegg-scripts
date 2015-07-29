expressio = require 'express.io'
peggAdmin = require './peggAdmin'
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
pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID

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
app.get '/choices', (req, res) ->
   pa._getTable 'Choice', (data) =>
     res.send data
#
# app.post '/choice', (req, res) ->
#   pp.updateRow 'Choice', req.body.id, { plug: req.body.orig, plugThumb: req.body.thumb }, (data) =>
#     res.send data

app.io.route 'migrateS3', (req) ->
  taskName = 'migrateS3'
  pa.on 'message', (message) ->
    req.io.emit 'message', { taskName, message }
  pa.on 'done', (cardId, results) ->
    req.io.emit 'done', { taskName, results, message: "Success! Images have been moved." }
  pa.on 'error', (error) ->
    console.log error.stack
    req.io.emit 'error', { taskName, error }
  console.log "migrating images to s3"
  pa.migrateImagesToS3()

app.io.route 'ready', (req) ->
  console.log 'client is ready'
  req.io.emit 'message', message: "ya let's do it!"

app.io.route 'deleteCard', (req) ->
  taskName = 'deleteCard'
  pa.on 'message', (message) ->
    req.io.emit 'message', { taskName, message }
  pa.on 'done', (cardId, results) ->
    req.io.emit 'done', { taskName, results, message: "Success! Card #{cardId} has been obliterated. It is no more." }
  pa.on 'error', (error) ->
    console.log error.stack
    req.io.emit 'error', { taskName, error }
  console.log "delete card #{req.data}"
  pa.deleteCard req.data

app.io.route 'resetUser', (req) ->
  taskName = 'resetUser'
  pa.on 'message', (message) ->
    req.io.emit 'message', { taskName, message }
  pa.on 'done', (userId, results) ->
    req.io.emit 'done', { taskName, results, message: "Success! User #{userId} is fresh like spring pheasant." }
  pa.on 'error', (error) ->
    console.log error.stack
    req.io.emit 'error', { taskName, error }
  console.log "reset user #{req.data}"
  pa.resetUser req.data

app.listen app.port, ->
  console.log "Listening on http://localhost:" + app.port + "/\nPress CTRL-C to stop server."
