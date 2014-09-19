Parse.initialize "oBVGtJcA1YL8qAHtRHE1sm46edv3CdxSDCCBAyH3", "jOzfgxXTgD83QGnSyEcJgdCGEE4tNQz2bMEP4Zxe"
filepicker.setKey "A36NnDQaISmXZ8IOmKGEQz"

class Migrate

  pickAndStore: ->
    filepicker.pickAndStore mimetype: "image/*", {path: '/uploaded/'}, (InkBlobs) ->
      result = InkBlobs[0]
      result.fullS3 = Config.s3.bucket + InkBlobs[0].key
      filepicker.convert InkBlobs[0], { width: 100, height: 100, fit: 'clip', format: 'jpg'} , { path: '/processed/' }, (thumbBlob) =>
        thumbBlob.s3 = Config.s3.bucket + thumbBlob.key
        result.thumb = thumbBlob


  fetchImageUrls: ->
    Choice = Parse.Object.extend 'Choice'
    choiceQuery = new Parse.Query Choice
    card = new Parse.Object 'Card'
  #  card.set 'id',  cardId
  #  choiceQuery.equalTo 'card', card
    choiceQuery.find
      success: (choices) =>
        if choices?.length > 0
          cb choices
        else
          cb null
      error: (error) ->
        console.log "Error fetching choices: " + error.code + " " + error.message
        cb null

window.migrate = new Migrate()
