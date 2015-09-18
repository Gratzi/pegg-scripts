log = -> console.log arguments...

class Client
  constructor: (@server) ->
    $('#createCard_form').on 'submit', @createCard
    $('#deleteCard').on      'submit', @deleteCard
    $('#resetUser').on       'submit', @resetUser
    $('#migrateS3').on       'submit', @migrateS3
    @server.io.on 'message', @onMessage
    @server.io.on 'done',    @onDone
    @server.io.on 'error',   @onError

  createCard: (e) =>
    data = $(e.currentTarget).serializeObject()
    log "creating card:", data
    @reset 'createCard'
    try
      @server.createCard data
    catch err
      @error 'createCard', err.message
    e.preventDefault()

  deleteCard: (e) =>
    cardId = $('#deleteCard_id').val()
    log "deleting card #{cardId}"
    @reset 'deleteCard'
    try
      @server.deleteCard cardId
    catch err
      @error 'deleteCard', err.message
    e.preventDefault()

  resetUser: (e) =>
    userId = $('#resetUser_id').val()
    log "resetting user #{userId}"
    @reset 'resetUser'
    try
      @server.resetUser userId
    catch err
      @error 'resetUser', err.message
    e.preventDefault()

  migrateS3: (e) =>
    log "migrating image content to S3"
    @reset 'migrateS3'
    try
      @server.migrateS3()
    catch err
      @error 'migrateS3', err.message
    e.preventDefault()

  onMessage: (data) =>
    log "server: ", data.message

  onDone: (data) =>
    $("##{data.data.task}_message")
      .html data.message
      .parent().addClass 'has-success'
    log "#{data.data.task} done!", data.data

  onError: (data) =>
    message = data?.error?.message or data?.error?.error ? 'Unknown error occurred'
    fullMessage = "ERROR: #{message} (see server output for details)"
    @error data.data.task, fullMessage

  error: (task, message) ->
    log message
    $("##{task}_message")
      .html message
      .parent()
        .addClass 'has-error'
        .removeClass 'has-success'

  reset: (task) ->
    $("##{task}_message")
      .html "working ..."
      .parent()
        .removeClass 'has-success'
        .removeClass 'has-error'

class ServerActions
  constructor: ->
    # listen to actions from server
    @io = window.io.connect()
    @io.emit 'ready'

  createCard: (data) ->
    # validate it and clean it up
    for choice, i in data.choices
      if _.isEmpty(choice.text) and _.isEmpty(choice.image.meta.url)
        data.choices[i] = undefined
      else
        choice.image.small = choice.image.meta.url
        choice.image.big = choice.image.meta.url

    if _.isEmpty(data.question)
      throw new Error 'Please enter a question'

    data.choices = _.compact data.choices
    if data.choices.length < 2
      throw new Error 'Please enter 2+ choices'

    # do the create thing
    @io.emit "create", type: 'Card', object: data, task: 'createCard'

  deleteCard: (cardId) ->
    @io.emit 'deleteCard', cardId

  resetUser: (userId) ->
    @io.emit 'resetUser', userId

  migrateS3: ->
    @io.emit 'migrateS3'

class App
  constructor: ->
    @server = new ServerActions
    @client = new Client @server
    @initRouting()

  initRouting: ->
    window.onhashchange = @hashChange
    if window.location.hash then @hashChange()

  hashChange: ->
    log "showing page #{window.location.hash}"
    $(".page").hide()
    $(window.location.hash).show()

# init the app
$(document).ready -> window.App = new App()
