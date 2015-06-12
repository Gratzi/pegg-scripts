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

  _deleteCard: (card) ->
    return Promise.resolve()
    @_parse.deleteAsync '', card.objectId
      .then =>
        @emit 'update', "deleted card: #{card.objectId}"

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

  deletePrefs: (conditions) =>
    # find prefs for these conditions, and return a promise
    @_parse.findAsync 'Pref', conditions
      .then (data) =>
        @emit 'update', "deleting #{data.results.length} prefs for #{@_pretty _.mapValues(conditions, (c) -> c.objectId)}"
        return Promise.resolve()
        # make a bunch of sub-promises that resolve when the row is successfully deleted, and
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Promise.all(
          for pref in data.results
            @_parse.deleteAsync 'Pref', pref.objectId
              .then =>
                @emit 'update', "deleted pref: #{@_pretty pref}"
        )

  deletePeggs: (conditions) =>
    # find peggs for these conditions, and return a promise
    @_parse.findAsync 'Pegg', conditions
      .then (data) =>
        @emit 'update', "deleting #{data.results.length} peggs for #{@_pretty _.mapValues(conditions, (c) -> c.objectId)}"
        return Promise.resolve()
        # make a bunch of sub-promises that resolve when the row is successfully deleted, and
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Promise.all(
          for pegg in data.results
            @_parse.deleteAsync 'Pegg', pegg.objectId
              .then =>
                @emit 'update', "deleted pegg: #{@_pretty pegg}"
        )

  clearHasPreffed: (userId) =>
    # get all the cards, and return a promise
    @getTable 'Card'
      .then (results) =>
        @emit 'update', "clearing hasPreffed from #{results.length} cards for user #{userId}"
        return Promise.resolve()
        # make a bunch of sub-promises that resolve when the row is successfully cleared, and
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all(
          for card in results
            if card.hasPreffed?.indexOf(userId) > -1
              card.hasPreffed = _.uniq(card.hasPreffed).splice userId, 1
              @_parse.updateAsync 'Card', card.objectId, card
                .then =>
                  @emit 'update', "cleared hasPreffed from card: #{card.objectId}"
        )

  clearHasPegged: (userId) =>
    # get all the cards, and return a promise
    @getTable 'Pref'
      .then (results) =>
        @emit 'update', "clearing hasPegged from #{results.length} prefs for user #{userId}"
        return Promise.resolve()
        # make a bunch of sub-promises that resolve when the row is successfully cleared, and
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all(
          for card in results
            if card.hasPegged?.indexOf(userId) > -1
              card.hasPegged = _.uniq(card.hasPegged).splice userId, 1
              @_parse.updateAsync 'Pref', card.objectId, card
                .then =>
                  @emit 'update', "cleared hasPegged from card: #{card.objectId}"
        )

  getTable: (type) ->
    @emit 'update', "getting table #{type}"
    @getRows type, 50, 0, []

  getRows: (type, limit, skip, res) ->
    @_parse.findManyAsync type, "?limit=#{limit}&skip=#{skip}"
      .then (data) =>
        if data?.results?.length > 0
          for item in data.results
            res.push item
          @getRows type, limit, skip + limit, res
        else
          res

  _pretty: (thing) ->
    JSON.stringify thing, null, 2

module.exports = PeggParse
