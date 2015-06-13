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
      @_delete 'Card', cardId
      @_findAndDelete 'Activity', card: card
      @_findAndDelete 'Choice', card: card
      @_findAndDelete 'Comment', card: card
      @_findAndDelete 'Favorite', card: card
      @_findAndDelete 'Frown', card: card
      @_findAndDelete 'Pegg', card: card
      @_findAndDelete 'PeggCounts', card: card
      @_findAndDelete 'Pref', card: card
      @_findAndDelete 'PrefCounts', card: card
    ])
      .then (results) => @emit 'done', cardId, results
      .catch (error) => @emit 'error', error

  resetUser: (userId) ->
    user =
      __type: "Pointer"
      className:"_User"
      objectId: userId

    Promise.all([
      # XXX If we want to enable (optionally) resetting user to pristine state, como
      # recién nacido, then we'd include the following items:
      #
      # @_findAndDelete 'Activity', user: user
      # @_findAndDelete 'Activity', friend: user
      # @_findAndDelete 'Comment', author: user
      # @_findAndDelete 'Comment', peggee: user
      # @_findAndDelete 'Favorite', user: user
      # @_findAndDelete 'Flag', peggee: user
      # @_findAndDelete 'Flag', user: user
      # @_findAndDelete 'Frown', user: user
      # @_findAndDelete 'Pegg', user: user
      # @_findAndDelete 'Pegg', peggee: user
      # @_findAndDelete 'PeggCounts', user: user
      # @_findAndDelete 'PeggerPoints', peggee: user
      # @_findAndDelete 'PeggerPoints', pegger: user
      # @_findAndDelete 'Pref', user: user
      # @_findAndDelete 'PrefMatch', friendA: user
      # @_findAndDelete 'PrefMatch', friendB: user
      # @_findAndDelete 'SupportComment', author: user
      # @_findAndDelete 'SupportComment', peggee: user
      # @_findAndDelete 'UserMood', user: user
      # @_findAndDelete 'UserSetting', user: user
      #
      # Also:
      # - find all cards made by user then @deleteCard
      # - if we wanted to be really thorough we'd collect IDs and counts for Peggs
      #   we delete and decrement PeggCounts
      #
      # To totally nuke the user, also include:
      # 
      # @_delete 'User', userId
      # @_findAndDelete 'Session', user: user
      # @_findAndDelete 'UserPrivates', user: user
      #
      @_findAndDelete 'Pref', user: user
      @_findAndDelete 'Pegg', user: user
      @clearHasPreffed userId
      @clearHasPegged userId
    ])
      .then (results) => @emit 'done', userId, results
      .catch (error) => @emit 'error', error

  clearHasPreffed: (userId) =>
    # get all the cards, and return a promise
    @_getTable 'Card'
      .then (results) =>
        @emit 'message', "clearing hasPreffed from #{results.length} cards for user #{userId}"
        # make a bunch of sub-promises that resolve when the row is successfully cleared, and
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all(
          for card in results
            if card.hasPreffed?.indexOf(userId) > -1
              card.hasPreffed = _.uniq(card.hasPreffed).splice userId, 1
              @_parse.updateAsync 'Card', card.objectId, card
                .then =>
                  @emit 'message', "cleared hasPreffed from card: #{card.objectId}"
        )

  clearHasPegged: (userId) =>
    # get all the cards, and return a promise
    @_getTable 'Pref'
      .then (results) =>
        @emit 'message', "clearing hasPegged from #{results.length} prefs for user #{userId}"
        # make a bunch of sub-promises that resolve when the row is successfully cleared, and
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all(
          for card in results
            if card.hasPegged?.indexOf(userId) > -1
              card.hasPegged = _.uniq(card.hasPegged).splice userId, 1
              @_parse.updateAsync 'Pref', card.objectId, card
                .then =>
                  @emit 'message', "cleared hasPegged from card: #{card.objectId}"
        )

  _getTable: (type) ->
    @emit 'message', "getting table #{type}"
    @_getRows type, 50, 0, []

  _getRows: (type, limit, skip, res) ->
    @_parse.findManyAsync type, "?limit=#{limit}&skip=#{skip}"
      .then (data) =>
        if data?.results?.length > 0
          for item in data.results
            res.push item
          @_getRows type, limit, skip + limit, res
        else
          res

  _findAndDelete: (type, conditions) ->
    # find items for these conditions, and return a promise
    @_parse.findAsync type, conditions
      .then (data) =>
        # @emit 'message', "found #{data.results.length} #{type} items where #{@_pretty  _.mapValues(conditions, (c) -> c.objectId)}"
        # make a bunch of sub-promises that resolve when the row is successfully deleted, and
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Promise.all(
          for item in data.results
            @_delete type, item.objectId
        )

  _delete: (type, objectId) ->
    @_parse.deleteAsync type, objectId
      .then =>
        @emit 'message', "deleted #{type}: #{objectId}"

  _pretty: (thing) ->
    JSON.stringify thing, null, 2

module.exports = PeggParse
