Parse.initialize "oBVGtJcA1YL8qAHtRHE1sm46edv3CdxSDCCBAyH3", "jOzfgxXTgD83QGnSyEcJgdCGEE4tNQz2bMEP4Zxe"
filepicker.setKey "A36NnDQaISmXZ8IOmKGEQz"

class Migrate

  moveImagesToS3: ->
    @fetchImageUrls 5, 0, [], (items) ->
      for item in items
        matches = item.url.match /[^\/]+(#|\?|$)/
        filename = "_#{item.id}.#{matches[0]}"
        path = '/full'
#        @saveImageToS3 item.url, filename, path, (inkBlob) =>
        console.log item

  pickAndStore: ->
    filepicker.pickAndStore mimetype: "image/*", {path: '/uploaded/'}, (InkBlobs) ->
      result = InkBlobs[0]
      result.fullS3 = Config.s3.bucket + InkBlobs[0].key
      filepicker.convert InkBlobs[0], { width: 100, height: 100, fit: 'clip', format: 'jpg'} , { path: '/processed/' }, (thumbBlob) =>
        thumbBlob.s3 = Config.s3.bucket + thumbBlob.key
        result.thumb = thumbBlob


  fetchImageUrls: (limit, skip, urls, cb) ->
    Choice = Parse.Object.extend 'Choice'
    choiceQuery = new Parse.Query Choice
#    card = new Parse.Object 'Card'
#    card.set 'id',  cardId
#    choiceQuery.equalTo 'card', card
    choiceQuery.limit limit
    choiceQuery.skip skip
    choiceQuery.find
      success: (choices) =>
        if choices?.length > 0
          for choice in choices
            urls.push { id: choice.objectId, url: choice.image }
#          fetchImageUrls limit, skip + limit, urls, cb
          cb urls
        else
          cb urls
      error: (error) ->
        console.log "Error fetching choices: " + error.code + " " + error.message
        cb null

  saveImagesToS3:  (url, filename, path, cb) ->



  saveUrlToParse:  (id, full, thumb, cb) ->
    choiceQuery = new Parse.Query 'Choice'
    choiceQuery.equalTo 'objectId', id
    choiceQuery.first
      success: (result) =>
        if result?
          result.set 'plugFull', full
          result.set 'plugThumb', thumb
          result.save()
          cb "success"
        else
          cb null

window.migrate = new Migrate()
