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
      storeImageFromUrl item.url, filename, "/full/#{filename}", (inkBlob) =>
        inkBlob = JSON.parse inkBlob
        console.log inkBlob
        updateFilename inkBlob.filename, item.id, (res) ->
          console.log res
        createThumbnail inkBlob, (res) ->
          console.log res


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


storeImageFromUrl = (url, filename, path, cb) ->
  command = "curl -X POST -d url='#{url}' https://www.filepicker.io/api/store/S3?key=#{config.filepicker_api_key}&filename=#{filename}"
  console.log command
  exec command, (error, stdout, stderr) ->
    cb stdout

updateFilename = (filename, id, cb) ->
  pp.updateRow 'Choice', filename, id, (err, data) ->
    if err?
      cb err
    else
      cb data

createThumbnail = (inkBlob, cb) ->
  url = inkBlob.url + "/convert?format=jpg&w=100&h=100"
  filename = "_thumb_#{inkBlob.filename}"
  storeImageFromUrl url, filename, "/thumbs/#{filename}", (res) ->
    cb res

migrateImagesToS3()
