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

parse_api = require("./pegg-parse")(config)

importFeeds = (err, res) ->
  http.get config.squishle_feed_url, (res) ->
    body = ""
    res.on "data", (chunk) ->
      body += chunk
      return

    res.on "end", ->
      feeds = JSON.parse(body).sets
      handleFeed = (index) ->
        parse_api.insertCard feeds[index], (err, data) ->
          if err
            console.log err
          else
            console.log index
            if index < feeds.length - 1
              handleFeed index + 1
            else
              console.log data
      handleFeed 0

importFeeds()