http = require 'http'
fs = require 'fs'

# Load config defaults from JSON file.
# Environment variables override defaults.
loadConfig = ->
  config = JSON.parse(fs.readFileSync(__dirname + "/../config.json", "utf-8"))
  for i of config
    config[i] = process.env[i.toUpperCase()] or config[i]
  console.log "Configuration"
  console.log config
  config
config = loadConfig()

pegg_parse = require("./pegg-parse")(config)

fetchImageUrls = ->
  pegg_parse.getRows 'Choice', 20, (data) ->
    for row in data
      convertImage(row.url)

convertImage = (url) ->
  filepicker.convert url
  filepicker.save inkblog