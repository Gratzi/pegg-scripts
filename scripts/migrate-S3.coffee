fs = require 'fs'
PeggParse = require './pegg-parse'
FilePicker = require 'node-filepicker'
request = require 'superagent'
exec = require('child_process').exec

# Load config defaults from JSON file.
# Environment variables override defaults.
config = JSON.parse fs.readFileSync(__dirname + "/../config.json", "utf-8")
for i of config
  config[i] = process.env[i.toUpperCase()] or config[i]
console.log '---------------------'
console.log '     MIGRATE S3      '
console.log '---------------------'
console.log config
console.log '---------------------'

pp = new PeggParse config

migrateImagesToS3 = ->
  fetchImageUrls 5, 0, [], (items) ->
    for item in items
      matches = item.url.match /[^\/]+(#|\?|$)/
      filename = "_#{item.id}.#{matches[0]}"
      console.log "#{item.id}, #{filename}"
      pushToS3 item.url, filename, (inkBlob) ->
        console.log inkBlob


fetchImageUrls = (limit, skip, urls, cb) ->
  pp.getRows 'Choice', limit, skip, (err, data) =>
    if data.results.length > 0
      for item in data.results
        if item.image isnt ""
          urls.push { id: item.objectId, url: item.image }
#      fetchImageUrls limit, skip + limit, urls, cb
      cb urls
    else
      cb urls


pushToS3 = (url, filename, cb) ->
  command = "curl -X POST -d url='#{url}' --data-urlencode 'filename=#{filename}' https://www.filepicker.io/api/store/S3?key=#{config.filepicker_api_key}"
  console.log command
  exec command, (error, stdout, stderr) ->
#    console.log error
#    console.log stderr
#    console.log stdout
    cb stdout

convertImage = (inkBlob) ->
  fp.convert inkBlob

migrateImagesToS3()


