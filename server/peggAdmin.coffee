fs = require 'fs'
Promise = require 'bluebird'
Parse = require('node-parse-api').Parse
_ = require 'lodash'
EventEmitter = require('events').EventEmitter
exec = require('child_process').exec

PARSE_OBJECT_ID = /^[0-z]{8}$/

class PeggAdmin extends EventEmitter

  constructor: (parseAppId, parseMasterKey, @filePickerId) ->
    super
    @_parse = Promise.promisifyAll(new Parse parseAppId, parseMasterKey)

  deleteCard: (cardId) ->
    unless cardId.match PARSE_OBJECT_ID
      return @_error "Invalid card ID: #{cardId}"

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
    unless userId.match PARSE_OBJECT_ID
      return @_error "Invalid user ID: #{userId}"

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
      @_findAndDelete 'Pegg', peggee: user
      @_findAndDelete 'Activity', user: user
      @_findAndDelete 'Activity', friend: user
      @_findAndDelete 'PeggerPoints', peggee: user
      @_findAndDelete 'PeggerPoints', pegger: user
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
    @_getRows type, 20, 0, []

  _getRows: (type, limit, skip, _res) ->
    @_parse.findManyAsync type, "?limit=#{limit}&skip=#{skip}"
      .then (data) =>
        console.log "Got records #{skip} - #{skip + limit} for #{type}"
        if data?.results?.length > 0
          for item in data.results
            _res.push item
          return _res
#          @_getRows type, limit, skip + limit, _res
        else
          _res

  _findAndDelete: (type, conditions) ->
    if _.isEmpty(conditions)
      return @_error "conditions should not be empty"
    # find items for these conditions, and return a promise
    @_parse.findAsync type, conditions
      .then (data) =>
        @emit 'message', "found #{data.results.length} #{type} items where #{@_pretty  _.mapValues(conditions, (c) -> c.objectId)}"
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


  _error: (message) ->
    error = { message: message, stack: new Error(message).stack }
    @emit 'error', error
    error

  migrateImagesToS3: ->
    @_getTable 'Choice'
      .then (results) =>
        for item in results when not _.isEmpty(item.image)
          @storeImageFromUrl item.image, item.objectId, "/premium/orig/", (inkBlob, id, url) =>
            console.log inkBlob
            try
#              @emit 'message', "uploaded choiceId: #{id}, url: #{url}"
              inkBlob = JSON.parse inkBlob



            catch
              @emit 'error', message: inkBlob + ', choiceId: ' + id + ', url: ' + url
#            updateFilename inkBlob.filename, item.id, (res) ->
#              console.log res
#            createThumbnail inkBlob, (res) ->
#              console.log res

  storeImageFromUrl: (url, id, path, cb) ->
    console.log url
    urlFilePath = url.match( /[^\/]+(#|\?|$)/ ) or 'foo'
    filename = "#{id}_#{urlFilePath[0]}"
    console.log "#{id}, #{filename}"
    command = "curl -X POST -d url='#{url}' 'https://www.filepicker.io/api/store/S3?key=#{@filePickerId}&path=#{path + filename}'"
    console.log command
    exec command, (error, stdout, stderr) ->
      cb stdout, url, id
#
#  updateFilename: (filename, id, cb) ->
#    pp.updateRow 'Choice', filename, id, (err, data) ->
#      if err?
#        cb err
#      else
#        cb data
#
#  createThumbnail: (inkBlob, cb) ->
#    url = inkBlob.url + "/convert?format=jpg&w=100&h=100"
#    filename = "_thumb_#{inkBlob.filename}"
#    storeImageFromUrl url, filename, "/thumbs/#{filename}", (res) ->
#      cb res

module.exports = PeggAdmin
