filepicker.setKey "A36NnDQaISmXZ8IOmKGEQz"
request = window.superagent
S3Bucket = "https://pegg.s3.amazonaws.com/"

class Migrate

  moveImagesToS3: ->
    @fetchImageUrls (items) =>
      for item in items.body
        if item.image? and item.image.length > 0
          matches = item.image.match /[^\/]+(#|\?|$)/
          filename = if matches? then "_#{item.objectId}_.#{matches[0]}" else "_#{item.objectId}_.jpg"
          image =
            id: item.objectId
            url: item.image
            name: filename
          @saveImageToS3 image, (InkBlob) =>
            @updateImageUrl InkBlob
      return null

  pickAndStore: ->
    filepicker.pickAndStore mimetype: "image/*", {path: '/uploaded/'}, (InkBlobs) ->
      result = InkBlobs[0]
      result.fullS3 = Config.s3.bucket + InkBlobs[0].key
      filepicker.convert InkBlobs[0], { width: 100, height: 100, fit: 'clip', format: 'jpg'} , { path: '/processed/' }, (thumbBlob) =>
        thumbBlob.s3 = S3Bucket + thumbBlob.key
        result.thumb = thumbBlob
      return null


  fetchImageUrls: (cb) ->
    request
      .get '/choices'
      .end (res) ->
        cb res
        return null

  updateImageUrl: (InkBlob) ->
    request
      .post '/choice'
      .send InkBlob
      .end (res) ->
        console.log res
        return null

  saveImageToS3:  (image, cb) ->
    combinedBlob = {}
    combinedBlob.id = image.id
    storeOptions =
      filename: image.name
      location: 'S3'
      path: '/orig/'
    filepicker.storeUrl image.url, storeOptions, (origBlob) =>
      combinedBlob.orig = origBlob
      combinedBlob.orig.S3 = S3Bucket + origBlob.key
      convertOptions =
        width: 100
        height: 100
        fit: 'clip'
        format: 'jpg'
      storeOptions.path = '/thumb/'
      filepicker.convert origBlob, convertOptions, storeOptions, (thumbBlob) =>
        combinedBlob.thumb = thumbBlob
        combinedBlob.thumb.S3 = S3Bucket + thumbBlob.key
        console.log JSON.stringify combinedBlob
        cb combinedBlob
      return null


window.migrate = new Migrate()
