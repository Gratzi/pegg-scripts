(function() {
  var Module, Parse;

  Parse = require("node-parse-api").Parse;

  module.exports = function(options) {
    if (!options) {
      options = {};
    }
    return new Module(options);
  };

  Module = function(options) {
    this.app = new Parse(options.app_id, options.master_key);
    return this;
  };

  Module.prototype = {
    insertCard: function(doc, cb) {
      var handleCategory, handleChoice, _self;
      handleChoice = function(cardId, doc, index) {
        return _self._insertChoice(cardId, doc, index, function(err, data) {
          if (err) {
            return cb(err);
          } else {
            if (index < 5) {
              return handleChoice(cardId, doc, index + 1);
            } else {
              return handleCategory(cardId, doc, 0);
            }
          }
        });
      };
      handleCategory = function(cardId, doc, index) {
        var categories;
        categories = doc.categories;
        if (categories.length > 0) {
          return _self._insertCategory(categories[index], function(err, categoryId) {
            if (err) {
              return cb(err);
            }
          });
        } else {
          return cb(null, true);
        }
      };
      _self = this;
      return this.app.find("Card", {
        squishleId: doc.guid
      }, function(err, res) {
        var categories;
        if (err) {
          return cb(err);
        } else {
          if (res.results.length > 0) {
            return handleChoice(res.results[0].objectId, doc, 1);
          } else {
            categories = doc.categories.map(function(cat) {
              return cat.name;
            });
            return _self.app.insert("Card", {
              question: doc.title,
              squishleId: doc.guid,
              categories: categories
            }, function(err, data) {
              if (err) {
                return cb(err);
              } else {
                return handleChoice(data.objectId, doc, 1);
              }
            });
          }
        }
      });
    },
    _insertChoice: function(cardId, doc, index, cb) {
      var cardPointer, img, txt, _self;
      _self = this;
      img = doc["image" + index];
      txt = doc["caption" + index];
      cardPointer = {
        __type: "Pointer",
        className: "Card",
        objectId: cardId
      };
      if (img === "" && txt === "") {
        return cb(null, "skipped");
      } else {
        return this.app.find("Choice", {
          card: cardPointer
        }, function(err, res) {
          var choices, found, i;
          if (err) {
            return cb(err);
          } else {
            choices = res.results;
            found = -1;
            if (choices.length > 0) {
              i = 0;
              while (i < choices.length) {
                if (choices[i].image === img && choices[i].text === txt) {
                  found = i;
                  break;
                }
                i++;
              }
            }
            if (found > -1) {
              return cb(null, choices[found].objectId);
            } else {
              return _self.app.insert("Choice", {
                card: cardPointer,
                image: img,
                text: txt
              }, function(err, data) {
                if (err) {
                  return cb(err);
                } else {
                  return cb(null, data.objectId);
                }
              });
            }
          }
        });
      }
    },
    _insertCategory: function(cat, cb) {
      var _self;
      _self = this;
      return this.app.find("Category", {
        name: cat.name
      }, function(err, res) {
        if (err) {
          return cb(err);
        } else {
          if (res.results.length > 0) {
            return cb(null, res.results[0].objectId);
          } else {
            return _self.app.insert("Category", {
              iconUrl: cat._id,
              name: cat.name
            }, function(err, data) {
              if (err) {
                return cb(err);
              } else {
                return cb(null, data.objectId);
              }
            });
          }
        }
      });
    },
    _insertCardCategory: function(cardId, categoryId, cb) {
      var cardPointer, categoryPointer, _self;
      _self = this;
      cardPointer = {
        __type: "Pointer",
        className: "Card",
        objectId: cardId
      };
      categoryPointer = {
        __type: "Pointer",
        className: "Category",
        objectId: categoryId
      };
      return this.app.find("CardCategory", {
        card: cardPointer,
        category: categoryPointer
      }, function(err, res) {
        if (err) {
          return cb(err);
        } else {
          if (res.results.length > 0) {
            return cb(null, res.results[0].objectId);
          } else {
            return _self.app.insert("CardCategory", {
              card: cardPointer,
              category: categoryPointer
            }, function(err, data) {
              if (err) {
                return cb(err);
              } else {
                return cb(null, data.objectId);
              }
            });
          }
        }
      });
    }
  };

}).call(this);
