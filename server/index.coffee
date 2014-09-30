express = require 'express'
peggParse = require './peggParse'
assets = require 'connect-assets'
bodyParser = require 'body-parser'

#### Basic application initialization
# Create app instance.
app = express()

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
app.use express.static process.cwd() + '/client'

pp = new peggParse config.PARSE_APP_ID, config.PARSE_MASTER_KEY

app.all '/', (req, res) ->
  res.render 'index'

app.get '/scripts', (req, res) ->
  list = require './list'
  list.serverScripts res

app.get '/choices', (req, res) ->
  pp.getTable 'Choice', (data) =>
    res.send data

app.post '/choice', (req, res) ->
  pp.updateRow 'Choice', req.body.id, { plug: req.body.orig, plugThumb: req.body.thumb }, (data) =>
    res.send data

app.all '/users/reset/:id', (req, res) ->
  console.log "reset user #{req.params.id}"
  pp.resetUser req.params.id, (result, status) =>
    res.status status
    res.send result

app.listen app.port, ->
  console.log "Listening on " + app.port + "\nPress CTRL-C to stop server."
