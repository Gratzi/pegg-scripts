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

    deletedPrefs = @deletePrefs user
    deletedPeggs = @deletePeggs user
    clearedHasPreffed = @clearHasPreffed userId
    clearedHasPegged = @clearHasPegged userId

    Parse.Promise.when deletedPrefs, deletedPeggs, clearedHasPreffed, clearedHasPegged

  deletePrefs: (user) =>
    # find prefs for this user, and return a promise
    @_parse.find 'Pref', user: user
      .then (data) =>
        # make a bunch of sub-promises that resolve when the row is successfully deleted
        prefRowsDeleted = []
        for row, i in data.results
          prefRowsDeleted[i] = @_parse.delete 'Pref', row.objectId
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Parse.Promise.when prefRowsDeleted

  deletePeggs: (user) =>
    # find peggs for this user, and return a promise
    @_parse.find 'Pegg', user: user
      .then (data) =>
        # make a bunch of sub-promises that resolve when the row is successfully deleted
        peggRowsDeleted = []
        for row, i in data.results
          peggRowsDeleted[i] = @_parse.delete 'Pegg', row.objectId
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Parse.Promise.when peggRowsDeleted

  _clearHasPreffed: (userId) =>
    # get all the cards, and return a promise
    @getTable 'Card'
      .then (results) =>
        preffedRowsCleared = []
        # make a bunch of sub-promises that resolve when the row is successfully cleared
        for row, i in results
          if row.hasPreffed? and row.hasPreffed.indexOf(userId) > -1
            row.hasPreffed.splice userId, 1
            preffedRowsCleared[i] = @_parse.update 'Card', row.objectId, row
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Parse.Promise.when preffedRowsCleared

  _clearHasPegged: (userId) =>
    # get all the cards, and return a promise
    @getTable 'Pref'
      .then (results) =>
        peggedRowsCleared = []
        # make a bunch of sub-promises that resolve when the row is successfully cleared
        for row, i in results
          if row.hasPegged? and row.hasPegged.indexOf(userId) > -1
            row.hasPegged.splice userId, 1
            peggedRowsCleared[i] = @_parse.update 'Pref', row.objectId, row
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Parse.Promise.when peggedRowsCleared

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
