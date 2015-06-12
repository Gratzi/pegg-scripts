fs = require 'fs'
Promise = require 'bluebird'
Parse = require('node-parse-api').Parse
_ = require 'lodash'
EventEmitter = require('events').EventEmitter

class PeggParse extends EventEmitter

  constructor: (appId, masterKey) ->
    super
    @_parse = Promise.promisifyAll(new Parse appId, masterKey)

  deleteCard: (cardId) ->
    card =
      __type: "Pointer"
      className:"Card"
      objectId: cardId

    Promise.all([
      @_deleteCard card
      @deletePrefs { card }
      @deletePeggs { card }
      # @deletePeggCounts { card }
      # @deletePrefCounts { card }
      # @deleteActivities { card }
      # @deleteChoices { card }
      # @deleteComments { card }
      # @deleteFavorites { card }
      # @deleteFrowns { card }
    ])
      .then (results) => @emit 'done', cardId, results
      .catch (error) => @emit 'error', error

  resetUser: (userId) ->
    user =
      __type: "Pointer"
      className:"_User"
      objectId: userId

    Promise.all([
      @deletePrefs { user }
      @deletePeggs { user }
      @clearHasPreffed userId
      @clearHasPegged userId
    ])
      .then (results) => @emit 'done', userId, results
      .catch (error) => @emit 'error', error

  _deleteCard: (card) ->
    message = "deleting card: #{card.objectId}"
    @emit 'update', message
    return Promise.resolve message: "all good"
    # find prefs for these conditions, and return a promise
    @_parse.deleteAsync '', card.objectId
      .then =>
        message = "deleted card: #{@_pretty card}"
        console.log message
        @emit 'update', message
        { message, pref }

  deletePrefs: (conditions) =>
    # find prefs for these conditions, and return a promise
    @_parse.findAsync 'Pref', conditions
      .then (data) =>
        message = "deleting #{data.results.length} prefs for #{@_pretty _.mapValues(conditions, (c) -> c.objectId)}"
        console.log message
        @emit 'update', message
        # console.log " -> results: #{@_pretty data}"
        # make a bunch of sub-promises that resolve when the row is successfully deleted
        return Promise.resolve message: "all good"
        prefRowsDeleted = []
        for pref, i in data.results
          prefRowsDeleted[i] = @_parse.deleteAsync 'Pref', pref.objectId
            .then =>
              message = "deleted pref: #{@_pretty pref}"
              console.log message
              @emit 'update', message
              { message, pref }
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Promise.all prefRowsDeleted

  deletePeggs: (conditions) =>
    # find peggs for this conditions, and return a promise
    @_parse.findAsync 'Pegg', conditions
      .then (data) =>
        message = "deleting #{data.results.length} peggs for #{@_pretty _.mapValues conditions, (c) -> c.objectId}"
        console.log message
        @emit 'update', message
        # console.log " -> results: #{@_pretty data}"
        # make a bunch of sub-promises that resolve when the row is successfully deleted
        return Promise.resolve message: "all good"
        peggRowsDeleted = []
        for pegg, i in data.results
          peggRowsDeleted[i] = @_parse.deleteAsync 'Pegg', pegg.objectId
            .then =>
              message = "deleted pegg: #{@_pretty pegg}"
              console.log message
              @emit 'update', message
              { message, pegg }
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Promise.all peggRowsDeleted

  clearHasPreffed: (userId) =>
    # get all the cards, and return a promise
    @getTable 'Card'
      .then (results) =>
        message = "clearing hasPreffed from #{results.length} cards for user #{userId}"
        console.log message
        @emit 'update', message
        # console.log " -> results: #{@_pretty results}"
        return Promise.resolve message: "all good"
        preffedRowsCleared = []
        # make a bunch of sub-promises that resolve when the row is successfully cleared
        for card, i in results
          if card.hasPreffed? and card.hasPreffed.indexOf(userId) > -1
            card.hasPreffed = _.uniq(card.hasPreffed).splice userId, 1
            preffedRowsCleared[i] = @_parse.updateAsync 'Card', card.objectId, card
              .then =>
                message = "cleared hasPreffed from card: #{card.objectId}"
                console.log message
                @emit 'update', message
                { message, card }
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all preffedRowsCleared

  clearHasPegged: (userId) =>
    # get all the cards, and return a promise
    @getTable 'Pref'
      .then (results) =>
        message = "clearing hasPegged from #{results.length} prefs for user #{userId}"
        console.log message
        @emit 'update', message
        # console.log " -> results: #{@_pretty results}"
        return Promise.resolve message: "all good"
        peggedRowsCleared = []
        # make a bunch of sub-promises that resolve when the row is successfully cleared
        for card, i in results
          if card.hasPegged? and card.hasPegged.indexOf(userId) > -1
            card.hasPegged = _.uniq(card.hasPegged).splice userId, 1
            peggedRowsCleared[i] = @_parse.updateAsync 'Pref', card.objectId, card
              .then =>
                message = "cleared hasPegged from card: #{card.objectId}"
                console.log message
                @emit 'update', message
                { message, card }
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all peggedRowsCleared

  getTable: (type) ->
    _args = _.values(arguments).join ', '
    console.log "getTable #{@_pretty _args}"
    @getRows type, 50, 0, []

  getRows: (type, limit, skip, res) ->
    _args = _.values(arguments).join ', '
    # console.log "getRows #{@_pretty _args}"
    @_parse.findManyAsync type, "?limit=#{limit}&skip=#{skip}"
      .then (data) =>
        # console.log "getRows > findManyAsync -> then"
        if data? and data.results? and data.results.length > 0
          # console.log " -> results: #{@_pretty data.results}"
          for item in data.results
            res.push item
          @getRows type, limit, skip + limit, res
        else
          # console.log " -> returning #{@_pretty _args}"
          res

  updateRow: (type, id, json) ->
    @_parse.updateAsync type, id, json

  _pretty: (thing) ->
    JSON.stringify thing, null, 2

module.exports = PeggParse
