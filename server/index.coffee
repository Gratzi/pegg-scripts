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

# body-parse application/json
app.use bodyParser.json()

# Add Connect Assets.
app.use assets()
# Set the client folder as static assets.
app.use expressio.static process.cwd() + '/client'

app.get '/', (req, res) ->
  res.render 'index'

# app.get '/choices', (req, res) ->
#   pa._getTable 'Choice'
#     .then (data) =>
#       res.json data


app.io.route 'ready', (req) ->
  console.log 'client is ready'
  req.io.emit 'message', message: "ya let's do it!"

app.io.route 'list', (req) ->
  pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
  type = req.data.type
  taskName = "get#{type}"
  pa.on 'message', (message) ->
    req.io.emit 'message', { taskName, message }
  pa.on 'done', (results) ->
    req.io.emit 'done', { taskName, results, message: "Success! #{req.data.type} listing complete" }
  pa.on 'error', (error) ->
    console.log error.stack
    req.io.emit 'error', { taskName, error }
  console.log "get #{JSON.stringify req.data}"
  pa._getTable type

app.io.route 'get', (req) ->
  pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
  taskName = "get#{req.data.type}"
  pa.on 'message', (message) ->
    req.io.emit 'message', { taskName, message }
  pa.on 'done', (results) ->
    req.io.emit 'done', { taskName, results, message: "Success! #{req.data.type} retrieved: #{results.objectId}" }
  pa.on 'error', (error) ->
    console.log error.stack
    req.io.emit 'error', { taskName, error }
  console.log "get #{JSON.stringify req.data}"
  pa.get req.data

app.io.route 'create', (req) ->
  pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
  taskName = "create#{req.data.type}"
  pa.on 'message', (message) ->
    req.io.emit 'message', { taskName, message }
  pa.on 'done', (results) ->
    req.io.emit 'done', { taskName, results, message: "Success! #{req.data.type} created: #{results.objectId}" }
  pa.on 'error', (error) ->
    console.log error.stack
    req.io.emit 'error', { taskName, error }
  console.log "create #{JSON.stringify req.data}"
  pa.create req.data

app.io.route 'update', (req) ->
  pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
  taskName = "update#{req.data.type}"
  pa.on 'message', (message) ->
    req.io.emit 'message', { taskName, message }
  pa.on 'done', (results) ->
    req.io.emit 'done', { taskName, results, message: "Success! #{req.data.type} updated: #{results.objectId}" }
  pa.on 'error', (error) ->
    console.log error.stack
    req.io.emit 'error', { taskName, error }
  console.log "update #{JSON.stringify req.data}"
  pa.update req.data

app.io.route 'delete', (req) ->
  pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
  taskName = "delete#{req.data.type}"
  pa.on 'message', (message) ->
    req.io.emit 'message', { taskName, message }
  pa.on 'done', (results) ->
    req.io.emit 'done', { taskName, results, message: "Success! #{req.data.type} deleted: #{results.objectId}" }
  pa.on 'error', (error) ->
    console.log error.stack
    req.io.emit 'error', { taskName, error }
  console.log "delete #{JSON.stringify req.data}"
  pa.delete req.data

app.io.route 'deleteCard', (req) ->
  pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
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
  pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
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

app.io.route 'migrateS3', (req) ->
  pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
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

app.listen app.port, ->
  console.log "Listening on http://localhost:" + app.port + "/\nPress CTRL-C to stop server."
