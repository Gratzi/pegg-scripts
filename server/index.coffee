express = require 'express'
peggParse = require './peggParse'

#### Basic application initialization
# Create app instance.
app = express()

# Define Port & Environment
app.port = process.env.PORT or process.env.VMC_APP_PORT or 3000
env = process.env.NODE_ENV or 'development'

# Config module exports has `setEnvironment` function that sets app settings depending on environment.
config = require './config'
config.setEnvironment env

pp = new peggParse config.PARSE_APP_ID, config.PARSE_MASTER_KEY

app.all '/scripts', (req, res) ->
  list = require './list'
  list.serverScripts res

app.all '/choices', (req, res) ->
  pp.getTable 'Choice', (data) =>
    res.send data

app.listen app.port, ->
  console.log "Listening on " + app.port + "\nPress CTRL-C to stop server."
