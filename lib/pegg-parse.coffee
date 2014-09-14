Parse = require("node-parse-api").Parse

module.exports = (options) ->
  options = {}  unless options
  new Module(options)

Module = (options) ->
  @app = new Parse(options.app_id, options.master_key)
  this

Module:: =
  insertCard: (doc, cb) ->
    handleChoice = (cardId, doc, index) ->
      _self._insertChoice cardId, doc, index, (err, data) ->
        if err
          cb err
        else
          if index < 5
            handleChoice cardId, doc, index + 1
          else
            handleCategory cardId, doc, 0

    handleCategory = (cardId, doc, index) ->
      categories = doc.categories
      if categories.length > 0
        _self._insertCategory categories[index], (err, categoryId) ->
          cb err  if err
      else
        cb null, true

    _self = this

    @app.find "Card", squishleId: doc.guid, (err, res) ->
      if err
        cb err
      else
        if res.results.length > 0
          handleChoice res.results[0].objectId, doc, 1
        else
          categories = doc.categories.map((cat) -> cat.name)
          _self.app.insert "Card", question: doc.title, squishleId: doc.guid, categories: categories, (err, data) ->
            if err
              cb err
            else
              handleChoice data.objectId, doc, 1

  _insertChoice: (cardId, doc, index, cb) ->
    _self = this
    img = doc["image" + index]
    txt = doc["caption" + index]

    cardPointer =
      __type: "Pointer"
      className: "Card"
      objectId: cardId

    if img is "" and txt is ""
      cb null, "skipped"
    else
      @app.find "Choice", card: cardPointer, (err, res) ->
        if err
          cb err
        else
          choices = res.results
          found = -1
          if choices.length > 0
            i = 0

            while i < choices.length
              if choices[i].image is img and choices[i].text is txt
                found = i
                break
              i++
          if found > -1
            cb null, choices[found].objectId
          else
            _self.app.insert "Choice", card: cardPointer, image: img, text: txt, (err, data) ->
              if err
                cb err
              else
                cb null, data.objectId


  _insertCategory: (cat, cb) ->
    _self = this
    @app.find "Category", name: cat.name, (err, res) ->
      if err
        cb err
      else
        if res.results.length > 0
          cb null, res.results[0].objectId
        else
          _self.app.insert "Category", iconUrl: cat._id, name: cat.name, (err, data) ->
            if err
              cb err
            else
              cb null, data.objectId


  _insertCardCategory: (cardId, categoryId, cb) ->
    _self = this
    cardPointer =
      __type: "Pointer"
      className: "Card"
      objectId: cardId

    categoryPointer =
      __type: "Pointer"
      className: "Category"
      objectId: categoryId

    @app.find "CardCategory", card: cardPointer, category: categoryPointer, (err, res) ->
      if err
        cb err
      else
        if res.results.length > 0
          cb null, res.results[0].objectId
        else
          _self.app.insert "CardCategory", card: cardPointer, category: categoryPointer, (err, data) ->
            if err
              cb err
            else
              cb null, data.objectId
