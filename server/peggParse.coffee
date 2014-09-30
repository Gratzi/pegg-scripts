fs = require 'fs'
Parse = require('node-parse-api').Parse


class PeggParse

  constructor: (appId, masterKey) ->
    @_parse = new Parse appId, masterKey

  resetUser: (userId, cb) ->
    user =
      __type: "Pointer"
      className:"_User"
      objectId: userId

    @_parse.find 'Pref', user: user, (err, data) =>
      console.log err
      for row in data.results
        @_parse.delete 'Pref', row.objectId, (err, data) =>
          console.log data or err

    @getTable 'Card', (results) =>
      console.log "userId: " + userId
      for row in results
        if row.hasPreffed?
          if row.hasPreffed.indexOf(userId) > -1
            row.hasPreffed.splice userId, 1
            @_parse.update 'Card', row.objectId, row, (err, data) =>
              console.log data or err

    @_parse.find 'Pegg', user: user, (err, data) =>
      for row in data.results
        @_parse.delete 'Pegg', row.objectId, (err, data) =>
          console.log data or err


    @getTable 'Pref', (results) =>
      console.log "userId: " + userId
      for row in results
        if row.hasPegged?
          if row.hasPegged.indexOf(userId) > -1
            row.hasPegged.splice userId, 1
            @_parse.update 'Pref', row.objectId, row, (err, data) =>
              console.log data or err


    success =
      message: "Success! User #{userId} is fresh like spring pheasant"
    failure =
      message: "FAIL!!! BOOOO!!!! OMGWTFBBQ"
    cb success, 200
    # cb failure, 500

  getTable: (type, cb) ->
    @getRows type, 50, 0, [], (items) ->
      cb items


  getRows: (type, limit, skip, res, cb) ->
    @_parse.findMany type, "?limit=#{limit}&skip=#{skip}", (err, data) =>
      if data? and data.results? and data.results.length > 0
        for item in data.results
          res.push item
#        cb res
        @getRows type, limit, skip + limit, res, cb
      else
        cb res

  updateRow: (type, id, json, cb) ->
    @_parse.update type, id, json, (err, data) ->
      if err?
        cb err
      else
        cb data

module.exports = PeggParse
