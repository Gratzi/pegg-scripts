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
  req.io.emit 'message', message: "ya let's do it!"

for key in Object.getOwnPropertyNames peggAdmin.prototype
  if (typeof peggAdmin.prototype[key] is 'function') and
    (key.charAt(0) isnt '_') and
    (key isnt 'constructor') then do (key) =>
      app.io.route key, (req) ->
        data = req.data
        pa = new peggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
        pa.on 'message', (message) -> req.io.emit 'message', { data, message }
        pa.on 'done', (results) -> req.io.emit 'done', { data, results }
        pa.on 'error', (error) ->
          console.log "ERROR: #{error.stack or JSON.stringify error}"
          req.io.emit 'error', { data, error }
        console.log "#{key} #{JSON.stringify data}"
        pa[key] data

app.listen app.port, ->
  console.log "Listening on http://localhost:" + app.port + "/\nPress CTRL-C to stop server."
