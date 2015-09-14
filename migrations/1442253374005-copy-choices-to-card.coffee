_ = require 'lodash'
Promise = require 'bluebird'
Parse = require('node-parse-api').Parse
PeggAdmin = require '../server/run/peggAdmin'


# Config module exports has `setEnvironment` function that sets app settings depending on environment.
config = require '../server/run/config'
env = process.env.NODE_ENV or 'development'
config.setEnvironment env

exports.up = (next) ->
  db = new PeggAdmin config.PARSE_APP_ID, config.PARSE_MASTER_KEY, config.FILE_PICKER_ID
  choices = []
  db.on 'results', (results) =>
    console.log "got #{results.length} choices"
    choices = choices.concat results

  db.findRecursive 'Choice',
      limit: 50
      skip: 0
      where:
        version: null
    .then =>
      console.log "#{choices.length} total choices"
      console.log "choice looks like: #{JSON.stringify _.first(choices), null, 2}"
      cards = _.groupBy choices, (choice) -> choice?.card?.objectId
      console.log "#{_.values(cards).length} total cards"
      console.log "card looks like: #{JSON.stringify _.first(_.values cards), null, 2}"
      for own cardId, card of cards
        cards[cardId] = _.map card, (choice) ->
          text: choice.text
          image: choice.blob or {
            big: choice.image
            small: choice.image
            meta:
              url: choice.image
              source: choice.imageSource
              credit: choice.imageCredit
          }
      console.log "card looks like: #{JSON.stringify _.first(_.values cards), null, 2}"

      # requests = _.map cards, (card) ->
      #   method: 'PUT'
      #   path: "/1/classes/Card/#{card.objectId}"
      #   body:
      #     choices: 'XXXXXXX'
    .then next

exports.down = (next) ->
  next()
