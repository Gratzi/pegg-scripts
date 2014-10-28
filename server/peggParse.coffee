fs = require 'fs'
Promise = require 'bluebird'
Parse = require('node-parse-api').Parse
_ = require 'underscore'

class PeggParse

  constructor: (appId, masterKey) ->
    @_parse = Promise.promisifyAll(new Parse appId, masterKey)

  resetUser: (userId) ->
    user =
      __type: "Pointer"
      className:"_User"
      objectId: userId

    deletedPrefs = @deletePrefs user
    deletedPeggs = @deletePeggs user
    clearedHasPreffed = @clearHasPreffed userId
    clearedHasPegged = @clearHasPegged userId

    Promise.all [deletedPrefs, deletedPeggs, clearedHasPreffed, clearedHasPegged]

  deletePrefs: (user) =>
    # find prefs for this user, and return a promise
    @_parse.findAsync 'Pref', user: user
      .then (data) =>
        console.log "deleting prefs for user #{user.objectId}"
        # console.log " -> results: #{@_pretty data}"
        # make a bunch of sub-promises that resolve when the row is successfully deleted
        prefRowsDeleted = []
        for pref, i in data.results
          prefRowsDeleted[i] = @_parse.deleteAsync 'Pref', pref.objectId
            .then =>
              message = "deleted pref: #{@_pretty pref}"
              console.log message
              { message, pref }
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Promise.all prefRowsDeleted

  deletePeggs: (user) =>
    # find peggs for this user, and return a promise
    @_parse.findAsync 'Pegg', user: user
      .then (data) =>
        console.log "deleting peggs for user #{user.objectId}"
        # console.log " -> results: #{@_pretty data}"
        # make a bunch of sub-promises that resolve when the row is successfully deleted
        peggRowsDeleted = []
        for pegg, i in data.results
          peggRowsDeleted[i] = @_parse.deleteAsync 'Pegg', pegg.objectId
            .then =>
              message = "deleted pegg: #{@_pretty pegg}"
              console.log message
              { message, pegg }
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Promise.all peggRowsDeleted

  clearHasPreffed: (userId) =>
    # get all the cards, and return a promise
    @getTable 'Card'
      .then (results) =>
        console.log "clearing hasPreffed for user #{userId}"
        # console.log " -> results: #{@_pretty results}"
        preffedRowsCleared = []
        # make a bunch of sub-promises that resolve when the row is successfully cleared
        for card, i in results
          if card.hasPreffed? and card.hasPreffed.indexOf(userId) > -1
            card.hasPreffed = _.uniq(card.hasPreffed).splice userId, 1
            preffedRowsCleared[i] = @_parse.updateAsync 'Card', card.objectId, card
              .then ->
                message = "cleared hasPreffed from card: #{card.objectId}"
                console.log message
                { message, card }
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all preffedRowsCleared

  clearHasPegged: (userId) =>
    # get all the cards, and return a promise
    @getTable 'Pref'
      .then (results) =>
        console.log "clearing hasPegged for user #{userId}"
        # console.log " -> results: #{@_pretty results}"
        peggedRowsCleared = []
        # make a bunch of sub-promises that resolve when the row is successfully cleared
        for card, i in results
          if card.hasPegged? and card.hasPegged.indexOf(userId) > -1
            card.hasPegged = _.uniq(card.hasPegged).splice userId, 1
            peggedRowsCleared[i] = @_parse.updateAsync 'Pref', card.objectId, card
              .then ->
                message = "cleared hasPegged from card: #{card.objectId}"
                console.log message
                { message, card }
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all peggedRowsCleared

  getTable: (type) ->
    _args = _.values(arguments).join ', '
    console.log "getTable #{@_pretty _args}"
    @getRows type, 50, 0, []

  getRows: (type, limit, skip, res) ->
    _args = _.values(arguments).join ', '
    console.log "getRows #{@_pretty _args}"
    @_parse.findManyAsync type, "?limit=#{limit}&skip=#{skip}"
      .then (data) =>
        console.log "getRows > findManyAsync -> then"
        if data? and data.results? and data.results.length > 0
          # console.log " -> results: #{@_pretty data.results}"
          for item in data.results
            res.push item
          @getRows type, limit, skip + limit, res
        else
          console.log " -> returning #{@_pretty _args}"
          res

  updateRow: (type, id, json) ->
    @_parse.updateAsync type, id, json

  _pretty: (thing) ->
    JSON.stringify thing, null, 2
module.exports = PeggParse
