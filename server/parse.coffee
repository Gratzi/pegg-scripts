fs = require 'fs'
PeggParse = require './pegg-parse'
pp = new PeggParse config

module.exports =

  getTable: (type) ->
    @getRows type, 5, 0, [], (items) ->
      for item in items
        matches = item.url.match /[^\/]+(#|\?|$)/
        filename = "_#{item.id}.#{matches[0]}"
        console.log "#{item.id}, #{filename}"
      return items

  getRows: (type, limit, skip, res, cb) ->
    pp.getRows type, limit, skip, (err, data) =>
      if data.results.length > 0
#        for item in data.results
#          if item.image isnt ""
#            res.push { id: item.objectId, url: item.image }
  #      getRows type, limit, skip + limit, urls, cb
        cb data.results
      else
        cb res

  updateRow: (type, column, id, cb) ->
    pp.updateRow type, column, id, (err, data) ->
      if err?
        cb err
      else
        cb data
