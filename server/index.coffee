express = require 'express'

#### Basic application initialization
# Create app instance.
app = express()

# Define Port & Environment
app.port = process.env.PORT or process.env.VMC_APP_PORT or 3000
env = process.env.NODE_ENV or 'development'

# Config module exports has `setEnvironment` function that sets app settings depending on environment.
config = require './config'
config.setEnvironment env

app.all '/list', (req, res) ->
  list = require './list'
  list.serverScripts res

app.all '/getRows', (req, res) ->
  console.log exports.DB_PORT
  parse = require './parse'
  parse.getTable 'Choice'

app.listen app.port, ->
  console.log "Listening on " + app.port + "\nPress CTRL-C to stop server."
