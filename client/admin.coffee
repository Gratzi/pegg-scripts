log = -> console.log arguments...

class Client
  constructor: (@server) ->
    $('#cardId').on     'submit',   @loadCard
    $('#loadCard').on   'click',    @loadCard
    $('#cardDetail').on 'submit',   @createOrUpdateCard
    $('#deleteCard').on 'submit',   @deleteCard
    $('#resetUser').on  'submit',   @resetUser
    $('#deleteUser').on 'submit',   @deleteUser
    $('#script_migrateS3').on  'submit', @migrateS3
    $('#script_updateBesties').on  'submit', @updateBesties
    @server.io.on 'message',    @onMessage
    @server.io.on 'done',       @onDone
    @server.io.on 'error',      @onError
    @server.io.on 'cardLoaded', @onCardLoaded

  ### Actions ###

  loadCard: (e) =>
    e.preventDefault()
    cardId = $('#cardId input[name="objectId"]').val()
    @do 'loadCard', id: cardId, section: 'loadCard'

  createOrUpdateCard: (e) =>
    data =
      card: $('#cardDetail').serializeObject()
      section: 'card'
    if data.card.objectId?.length > 0
      log "upadating card:", data
      @do 'updateCard', data
    else
      log "creating card:", data
      @do 'createCard', data
    e.preventDefault()

  deleteCard: (e) =>
    cardId = $('#deleteCard input[name="cardId"]').val()
    log "deleting card #{cardId}"
    @do 'deleteCard',
      section: 'deleteCard'
      cardId: cardId
    e.preventDefault()

  deleteUser: (e) =>
    userId = $('#deleteUser input[name="userId"]').val()
    log "deleting user #{userId}"
    @do 'deleteUser',
      section: 'deleteUser'
      userId: userId
    e.preventDefault()

  resetUser: (e) =>
    userId = $('#resetUser input[name="userId"]').val()
    log "resetting user #{userId}"
    @do 'resetUser',
      section: 'resetUser'
      userId: userId
    e.preventDefault()

  migrateS3: (e) =>
    log "migrating image content to S3"
    @do 'migrateImagesToS3', section: 'scripts'
    e.preventDefault()

  updateBesties: (e) =>
    log "updating bestie scores"
    @do 'updateBesties', section: 'scripts'
    e.preventDefault()

  ### Server Listeners ###

  onMessage: (data) =>
    log "server: ", data

  onDone: ({data, results, message}) =>
    section = data.section
    $("##{section} .message")
      .html message
      .parent().addClass 'has-success'
    log "#{data.section} done!", data
    @resetForm section

  onError: (data) =>
    message = data?.error?.message or data?.error?.error ? 'Unknown error occurred'
    fullMessage = "ERROR: #{message} (see server output for details)"
    @error data.data.section, fullMessage

  onCardLoaded: (data) =>
    @resetForm 'card'
    $('#card input[name="objectId"]').val data.objectId
    $('#card input[name="question"]').val data.question
    data.choices = _.values data.choices
    for choice, i in data.choices
      $('#card input[name="choices['+i+'][text]"]').val choice.text
      $('#card input[name="choices['+i+'][image][meta][url]"]').val choice.image.meta.url
      $('#card input[name="choices['+i+'][image][meta][source]"]').val choice.image.meta.source
      $('#card input[name="choices['+i+'][image][meta][credit]"]').val choice.image.meta.credit

  ### Helpers ###

  error: (section, message) ->
    console.error message
    $("##{section} .message")
      .html message
      .parent()
        .addClass 'has-error'
        .removeClass 'has-success'

  do: (task, data) =>
    @resetStyles data.section
    @showWorkingMessage data.section
    try
      @server.do task, data
    catch err
      @error data.section, err.message

  showWorkingMessage: (section) ->
    $("##{section} .message")
      .html "working ..."

  resetForm: (section) ->
    $("##{section} form").each ->
      @reset()

  resetStyles: (section) ->
    $("##{section} .message")
      .parent()
        .removeClass 'has-success'
        .removeClass 'has-error'

class ServerActions
  constructor: ->
    # listen to actions from server
    @io = window.io.connect()
    @io.emit 'ready'

  do: (task, data) =>
    if @[task]?
      @[task] data
    else
      @io.emit task, data

  _cleanupCard: (card) ->
    for choice, i in card.choices
      if _.isEmpty(choice.text) and _.isEmpty(choice.image.meta.url)
        card.choices[i] = undefined
      else
        choice.image.small = choice.image.meta.url
        choice.image.big = choice.image.meta.url
    card.choices = _.compact card.choices

  _validateCard: (card) ->
    if _.isEmpty(card.question)
      throw new Error 'Please enter a question'

    if card.choices.length < 2
      throw new Error 'Please enter 2+ choices'

  updateCard: (data) ->
    @_cleanupCard data.card
    @_validateCard data.card
    @io.emit 'updateCard', data

  createCard: (data) ->
    @_cleanupCard data.card
    @_validateCard data.card
    @io.emit 'createCard', data

class App
  constructor: ->
    @server = new ServerActions
    @client = new Client @server
    @initRouting()

  initRouting: ->
    window.onhashchange = @hashChange
    if window.location.hash then @hashChange()

  hashChange: ->
    page = window.location.hash or '#home'
    log "showing page #{page}"
    $(".page").hide()
    $(page).show()

# init the app
$(document).ready -> window.App = new App()
