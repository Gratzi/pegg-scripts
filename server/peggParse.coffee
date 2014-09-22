fs = require 'fs'
Parse = require('node-parse-api').Parse


class PeggParse

  constructor: (appId, masterKey) ->
    @_parse = new Parse appId, masterKey

  getTable: (type, cb) ->
    @getRows type, 5, 0, [], (items) ->
#      for item in items
#        matches = item.url.match /[^\/]+(#|\?|$)/
#        filename = "_#{item.id}.#{matches[0]}"
#        console.log "#{item.id}, #{filename}"
      cb items

  getRows: (type, limit, skip, res, cb) ->
    @_parse.findMany type, "?limit=#{limit}&skip=#{skip}", (err, data) ->
      if data.results.length > 0
#        for item in data.results
#          if item.image isnt ""
#            res.push { id: item.objectId, url: item.image }
  #      getRows type, limit, skip + limit, urls, cb
        cb data.results
      else
        cb res

  updateRow: (type, column, id, cb) ->
    @_parse.updateRow type, column, id, (err, data) ->
      if err?
        cb err
      else
        cb data

module.exports = PeggParse
