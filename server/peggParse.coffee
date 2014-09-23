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
    @_parse.findMany type, "?limit=#{limit}&skip=#{skip}", (err, data) =>
      if data? and data.results? and data.results.length > 0
        for item in data.results
          res.push item
        cb res
#        @getRows type, limit, skip + limit, res, cb
      else
        cb res

  updateRow: (type, column, id, cb) ->
    @_parse.updateRow type, column, id, (err, data) ->
      if err?
        cb err
      else
        cb data

module.exports = PeggParse
