http = require 'http'
fs = require 'fs'
PeggParse = require './pegg-parse'

# Load config defaults from JSON file.
# Environment variables override defaults.
config = JSON.parse(fs.readFileSync(__dirname + "/../config.json", "utf-8"))
for i of config
  config[i] = process.env[i.toUpperCase()] or config[i]
console.log '---------------------'
console.log '   IMPORT SQUISHLE   '
console.log '---------------------'
console.log config
console.log '---------------------'

pp = new PeggParse(config)

importFeeds = (err, res) ->
  http.get config.squishle_feed_url, (res) ->
    body = ""
    res.on "data", (chunk) ->
      body += chunk
      return

    res.on "end", ->
      feeds = JSON.parse(body).sets
      handleFeed = (index) ->
        pp.insertCard feeds[index], (err, data) ->
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