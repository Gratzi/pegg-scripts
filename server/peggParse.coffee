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
        console.log "deleting prefs for user #{JSON.stringify user}"
        # make a bunch of sub-promises that resolve when the row is successfully deleted
        prefRowsDeleted = []
        for pref, i in data.results
          prefRowsDeleted[i] = @_parse.deleteAsync 'Pref', pref.objectId
            .then (pref) ->
              message = "deleted pref: #{JSON.stringify pref}"
              console.log message
              { message, pref }
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Promise.all prefRowsDeleted

  deletePeggs: (user) =>
    # find peggs for this user, and return a promise
    @_parse.findAsync 'Pegg', user: user
      .then (data) =>
        console.log "deleting peggs for user #{JSON.stringify user}"
        # make a bunch of sub-promises that resolve when the row is successfully deleted
        peggRowsDeleted = []
        for pegg, i in data.results
          peggRowsDeleted[i] = @_parse.deleteAsync 'Pegg', pegg.objectId
            .then (pegg) ->
              message = "deleted pegg: #{JSON.stringify pegg}"
              console.log message
              { message, pegg }
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Promise.all peggRowsDeleted

  clearHasPreffed: (userId) =>
    # get all the cards, and return a promise
    @getTable 'Card'
      .then (results) =>
        console.log "clearing hasPreffed for user #{userId}"
        preffedRowsCleared = []
        # make a bunch of sub-promises that resolve when the row is successfully cleared
        for card, i in results
          if card.hasPreffed? and card.hasPreffed.indexOf(userId) > -1
            card.hasPreffed = _.uniq(card.hasPreffed).splice userId, 1
            preffedRowsCleared[i] = @_parse.updateAsync 'Card', card.objectId, card
              .then (card) ->
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
        peggedRowsCleared = []
        # make a bunch of sub-promises that resolve when the row is successfully cleared
        for card, i in results
          if card.hasPegged? and card.hasPegged.indexOf(userId) > -1
            card.hasPegged = _.uniq(card.hasPegged).splice userId, 1
            peggedRowsCleared[i] = @_parse.updateAsync 'Pref', card.objectId, card
              .then (card) ->
                message = "cleared hasPegged from card: #{card.objectId}"
                console.log message
                { message, card }
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all peggedRowsCleared

  getTable: (type, cb) ->
    @getRows type, 50, 0, [], (items) ->
      cb items

  getRows: (type, limit, skip, res, cb) ->
    @_parse.findManyAsync type, "?limit=#{limit}&skip=#{skip}", (err, data) =>
      if data? and data.results? and data.results.length > 0
        for item in data.results
          res.push item
#        cb res
        @getRows type, limit, skip + limit, res, cb
      else
        cb res

  updateRow: (type, id, json, cb) ->
    @_parse.updateAsync type, id, json, (err, data) ->
      if err?
        cb err
      else
        cb data

module.exports = PeggParse
