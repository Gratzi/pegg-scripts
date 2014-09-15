fs = require 'fs'
PeggParse = require './pegg-parse'
FilePicker = require 'node-filepicker'
request = require 'superagent'

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
fp = new FilePicker config.filepicker_api_key

migrateImagesToS3 = ->
  fetchImageUrls 100, 0, [], (urls) ->
    for url in urls
      fetchRawImage url, (image) ->
        pushToS3 image, (inkBlob) ->
          console.log inkBlob

fetchImageUrls = (limit, skip, urls, cb) ->
  pp.getRows 'Choice', limit, skip, (err, data) ->
    if data?
      for own d of data
        urls.push d.image
      fetchImageUrls limit, skip + limit, urls.push data, cb
    else
      cb urls

fetchRawImage = (url, cb) ->
  request
    .get(url)
    .end( (err, res) ->
      cb res
    )

pushToS3 = (image, cb) ->
  fp.store(payload, filename, mimetype, query, [callback]).then (inkBlob) ->
    inkBlob = JSON.parse(inkBlob)
    cb inkBlob


convertImage = (inkBlob) ->
  fp.convert inkBlob

migrateImagesToS3()


