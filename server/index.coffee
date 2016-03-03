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

app.io.route 'ready', (req) ->
  console.log 'client is ready'
  req.io.emit 'message', "ya let's do it!"

handleError = (error, req) ->
  console.log "ERROR: #{error.stack or JSON.stringify error}"
  req.io.emit 'error', { data: req.data, error }

# set up routes for methods in PeggAdmin
for key in Object.getOwnPropertyNames peggAdmin.prototype
  if (typeof peggAdmin.prototype[key] is 'function') and
    (key.charAt(0) isnt '_') and
    (key isnt 'constructor') then do (key) =>
      app.io.route key, (req) ->
        data = req.data
        pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
        pa.on 'error', (error) -> handleError error, req
        pa.onAny (event, data) ->
          unless event is 'error'
            req.io.emit event, data
        pa[key] data
          .then (results) -> req.io.emit 'done', { data, results, message: 'Success!' }
          .catch (error) -> handleError error, req

app.listen app.port, ->
  console.log "Listening on http://localhost:" + app.port + "/\nPress CTRL-C to stop server."
