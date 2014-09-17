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
  fetchImageUrls 5, 0, [], (items) ->
    for item in items
      fetchRawImage item.id, item.url, (res) ->
        if res? and res.body?
          id = res.req._headers['id']
          matches = res.header['content-type'].match /[^\/]+$/
          extension = matches[0]
          filename = "_#{id}.#{extension}"
          console.log "#{id}, #{filename}, #{res.header['content-type']}, #{res.req._headers['url']}, #{res.header['content-length']}, #{res.body.data.length}"
#          console.log res
          pushToS3 res.body.data, filename, res.header['content-type'], (inkBlob) ->
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


fetchRawImage = (id, url, cb) ->
  request
    .get(url)
    .set('id', id)
    .set('url', url)
    .buffer(true)
    .parse(binaryParser)
    .end( (err, res) ->
      if err?
        console.log err
        cb null
      else
#        console.log("res=", res.body)
        cb res
    )

binaryParser = (res, callback) ->
  console.log "binaryParser ftw"
  res.setEncoding "binary"
  res.data = ""
  res.on "data", (chunk) ->
    console.log "got some data..."
    res.data += chunk
  res.on "end", ->
    console.log "all #done"
    callback null, new Buffer(res.data, "binary")


pushToS3 = (payload, filename, mimetype, cb) ->
  fp.store(payload, filename, mimetype, null, cb).then (inkBlob) ->
    console.log inkBlob
#    inkBlob = JSON.parse(inkBlob)
    cb inkBlob


convertImage = (inkBlob) ->
  fp.convert inkBlob

migrateImagesToS3()


