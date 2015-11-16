fs = require 'fs'
Promise = require 'bluebird'
Parse = require('node-parse-api').Parse
_ = require 'lodash'
EventEmitter = require('events').EventEmitter
exec = require('child_process').exec

PARSE_OBJECT_ID = /^[0-z]{8,10}$/
PARSE_MAX_RESULTS = 1000

class PeggAdmin extends EventEmitter

  constructor: (parseAppId, parseMasterKey, @filePickerId) ->
    super
    @_parse = Promise.promisifyAll(new Parse parseAppId, parseMasterKey)

  get: ({type, id}) ->
    @_parse.findWithObjectIdAsync type, id
      .then (results) =>
        @emit 'done', results
        results
      .catch (error) => @emit 'error', error

  create: ({type, object}) ->
    @emit 'message', "creating #{type}"
    @_parse.insertAsync type, object

  update: ({type, id, object}) ->
    @_parse.updateAsync type, id, object

  delete: ({type, id}) ->
    @_delete type, id

  createCard: (data) ->
    card = data
    choices = card.choices
    card.choices = undefined
    @create type: 'Card', object: card
      .then (results) =>
        cardId = results.objectId
        data.objectId = cardId
        for choice in choices then do (choice) =>
          choice.card = @_pointer 'Card', cardId
          @create type: 'Choice', object: choice

  updateBatchRecursive: (requests, offset) ->
    newOffset = offset + 50 # max batch size
    @_parse.batchAsync _.slice requests, offset, newOffset
      .then (results) =>
        if results?.length > 0
          @emit 'update', results
          @updateBatchRecursive requests, newOffset

  # list: ({type, limit}) ->
  #   if limit? and limit > PARSE_MAX_RESULTS
  #     @findRecursive type, PARSE_MAX_RESULTS, 0
  #       .then (results) => @emit 'done', results
  #       .catch (error) => @emit 'error', error
  #   else
  #     @_parse.findManyAsync type, limit
  #       .then (results) => @emit 'done', results
  #       .catch (error) => @emit 'error', error

  findRecursive: (type, query) ->
    @_parse.findAsync type, query
      .then (data) =>
        if data?.results?.length > 0
          @emit 'fetch', data.results
          query.skip += query.limit
          @findRecursive type, query

  deleteCard: ({cardId}) ->
    unless cardId.match PARSE_OBJECT_ID
      return @_error "Invalid card ID: #{cardId}"

    card = @_pointer 'Card', cardId

    Promise.all([
      @clearCardFromFriendship card
      @_delete 'Card', cardId
      @_findAndDelete 'Choice', card: card
      @_findAndDelete 'Comment', card: card
      @_findAndDelete 'Favorite', card: card
      @_findAndDelete 'Frown', card: card
      @_findAndDelete 'Pegg', card: card
      @_findAndDelete 'Pref', card: card
    ])
      .then (results) => @emit 'done', cardId, results
      .catch (error) => @emit 'error', error

  clearCardFromFriendship: (card) =>
    cardId = card.objectId
    @_getTable 'Friendship'
      .then (friendships) =>
        @emit 'message', "got #{friendships.length} friendships"
        @emit 'message', "clearing card #{cardId} from friendships"
        # make a bunch of sub-promises that resolve when the row is successfully cleared, and
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all(
          for friendship in friendships
            originalFriendship = _.cloneDeep friendship
            _.pull friendship.cardsMatched, cardId
            _.pull friendship.cardsPegged, cardId
            _.pull friendship.prefsMatched, cardId
            friendship.cardsMatchedCount = friendship.cardsMatched.length
            friendship.cardsPeggedCount = friendship.cardsPegged.length
            friendship.prefsMatchedCount = friendship.prefsMatched.length
            unless _.isEqual friendship, originalFriendship
              @_parse.updateAsync 'Friendship', friendship.objectId, friendship
                .then do (cardId, friendship) => =>
                  @emit 'message', "cleared cardsMatched, cardsPegged, and prefsMatched for card #{cardId} from friendship: #{friendship.objectId}"
            else null
        )

  deleteUser: ({userId}) ->
    unless userId.match PARSE_OBJECT_ID
      return @_error "Invalid user ID: #{userId}"

    user = @_pointer '_User', userId

    Promise.all([
      # XXX If we want to enable (optionally) resetting user to pristine state, como
      # recién nacido, then we'd include the following items:
      #
      @_findAndDelete 'Comment', author: user
      @_findAndDelete 'Comment', peggee: user
      @_findAndDelete 'Favorite', user: user
      @_findAndDelete 'Friendship', user: user
      @_findAndDelete 'Friendship', friend: user
      @_findAndDelete 'Flag', peggee: user
      @_findAndDelete 'Flag', user: user
      @_findAndDelete 'Frown', user: user
      @_findAndDelete 'Pegg', user: user
      @_findAndDelete 'Pegg', peggee: user
      @_findAndDelete 'Pref', user: user
      @_findAndDelete 'SupportComment', author: user
      @_findAndDelete 'SupportComment', peggee: user
      @_findAndDelete 'UserMood', user: user
      @_findAndDelete 'UserSetting', user: user
      #
      # Also:
      # - find all cards made by user then @deleteCard
      # - if we wanted to be really thorough we'd collect IDs and counts for Peggs
      #   we delete and decrement PeggCounts
      #
      # To totally nuke the user, also include:
      #
      @_delete '_User', userId
      @_findAndDelete '_Session', user: user
      @_findAndDelete '_Role', name: "#{userId}_FacebookFriends"
      @_findAndDelete '_Role', name: "#{userId}_Friends"
      @_findAndDelete 'UserPrivates', user: user
      #
      @_findAndDelete 'Pref', user: user
      @_findAndDelete 'Pegg', user: user
      @_findAndDelete 'Pegg', peggee: user
      @clearHasPreffed {userId}
      @clearHasPegged {userId}
    ])
      .then (results) => @emit 'done', userId, results
      .catch (error) => @emit 'error', error

  resetUser: ({userId}) ->
    unless userId.match PARSE_OBJECT_ID
      return @_error "Invalid user ID: #{userId}"

    user = @_pointer '_User', userId

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
      # @_findAndDelete 'Pref', user: user
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
      @_findAndDelete 'Pegg', peggee: user
      @clearHasPreffed {userId}
      @clearHasPegged {userId}
    ])
      .then (results) => @emit 'done', userId, results
      .catch (error) => @emit 'error', error

  clearHasPreffed: ({userId}) =>
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

  clearHasPegged: ({userId}) =>
    # get all the cards, and return a promise
    @_getTable 'Pref'
      .then (results) =>
        @emit 'message', "clearing hasPegged from #{results.length} prefs for user #{userId}"
        # make a bunch of sub-promises that resolve when the row is successfully cleared, and
        # return a promise that resolves iff all of the rows were cleared, otherwise fails
        Promise.all(
          for pref in results
            if pref.hasPegged?.indexOf(userId) > -1
              pref.hasPegged = _.uniq(pref.hasPegged).splice userId, 1
              @_parse.updateAsync 'Pref', pref.objectId, pref
                .then =>
                  @emit 'message', "cleared hasPegged from pref: #{pref.objectId}"
        )

  migrateImagesToS3: ->
    @_getTable 'Choice'
      .then (results) =>
        for item in results when not _.isEmpty(item.image)
          urlFilePath = item.image.match( /[^\/]+(#|\?|$)/ ) or 'foo'
          filename = "#{item.objectId}_#{urlFilePath[0]}"
          item.original = item.image
          # console.log "#{url}, #{id}, #{filename}"
          @_storeImageFromUrl item, filename, "/premium/big/"
            .then (results) =>
              bigBlob = results.blob
              item = results.item
              console.log "bigBlob: ", bigBlob

              try
  #              @emit 'message', "uploaded choiceId: #{id}, url: #{url}"
                bigBlob = JSON.parse bigBlob
              catch
                message = bigBlob + ', choiceId: ' + item.objectId + ', url: ' + item.image
                @emit 'error',
                  message: message
                  stack: new Error(message).stack

              @_createThumbnail item, bigBlob
                .error (error) =>
                  @emit 'error', error
                .then (results) =>
                  console.log JSON.stringify(results)
                  try
                    smallBlob = JSON.parse results.blob
                    item = results.item
                    blob =
                      small: smallBlob.key
                      big: bigBlob.key
                      meta:
                        id: item.objectId
                        url: item.image
                        original: item.original
                        source: item.imageSource
                        credit: item.imageCredit
                      type: 'premium'
                    console.log "blob: ", blob
                    choice = {blob}
                    return @update type: 'Choice', id: item.objectId, object: choice
                      .then (res) =>
                        @emit 'message', "updated choice #{item.objectId}"
                      .catch (error) =>
                        @emit 'error', error
                  catch error
                    message = "#{error}, choiceId: #{item.objectId}, url: #{item.image}, smallBlob: #{JSON.stringify(smallBlob)}"
                    @emit 'error',
                      message: message
                      stack: new Error(message).stack

  _storeImageFromUrl: (item, filename, path) ->
    new Promise (resolve, reject) =>
      command = "curl -X POST -d url='#{item.image}' 'https://www.filepicker.io/api/store/S3?key=#{@filePickerId}&path=#{path + filename}'"
      console.log "command:", command
      exec command, (error, stdout, stderr) =>
        resolve { item: item, blob: stdout }

  _createThumbnail: (item, inkBlob) ->
    new Promise (resolve, reject) =>
      item.image = inkBlob.url + "/convert?format=jpg&w=375&h=667"
      filename = "#{item.objectId}_#{inkBlob.filename}"
      resolve @_storeImageFromUrl item, filename, "/premium/small/"

  _getTable: (type) ->
    @emit 'message', "getting table #{type}"
    @_getRows type, 1000, 0

  _getRows: (type, limit, skip, _res = []) ->
    @_parse.findManyAsync type, "?limit=#{limit}&skip=#{skip}"
      .then (data) =>
        console.log "Got records #{skip} - #{skip + limit} for #{type}"
        if data?.results?.length > 0
          for item in data.results
            _res.push item
          @_getRows type, limit, skip + limit, _res
        else
          _res

  _findAndDelete: (type, conditions) ->
    if _.isEmpty(conditions)
      return @_error "conditions should not be empty"
    # find items for these conditions, and return a promise
    @_parse.findAsync type, where: conditions
      .then (data) =>
        @emit 'message', "found #{data?.results?.length} #{type} items where #{@_pretty conditions}"
        # make a bunch of sub-promises that resolve when the row is successfully deleted, and
        # return a promise that resolves iff all of the rows were deleted, otherwise fails
        Promise.all(
          for item in data?.results
            @_delete type, item.objectId
        )

  _delete: (type, objectId) ->
    @_parse.deleteAsync type, objectId
      .then =>
        @emit 'message', "deleted #{type}: #{objectId}"

  _pretty: (thing) ->
    JSON.stringify thing, null, 2


  _error: (message) ->
    error = { message: message, stack: new Error(message).stack }
    Promise.reject error

  _pointer: (type, id) ->
    throw new Error "pointer type required" unless type?
    throw new Error "pointer object ID required" unless id?
    __type: "Pointer"
    className: type
    objectId: id

module.exports = PeggAdmin
