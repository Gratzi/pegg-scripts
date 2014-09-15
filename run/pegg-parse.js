(function() {
  var Parse, PeggParse;

  Parse = require("node-parse-api").Parse;

  PeggParse = (function() {
    function PeggParse(options) {
      if (!options) {
        options = {};
      }
      this.parse = new Parse(options.parse_app_id, options.parse_master_key);
    }

    PeggParse.prototype.getRows = function(type, num, cb) {
      return this.parse.findMany(type, '', function(err, res) {
        return cb(err, res);
      });
    };

    PeggParse.prototype.insertCard = function(doc, cb) {
      var handleCategory, handleChoice;
      handleChoice = (function(_this) {
        return function(cardId, doc, index) {
          return _this._insertChoice(cardId, doc, index, function(err, data) {
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
      })(this);
      handleCategory = (function(_this) {
        return function(cardId, doc, index) {
          var categories;
          categories = doc.categories;
          if (categories.length > 0) {
            return _this._insertCategory(categories[index], function(err, categoryId) {
              if (err) {
                return cb(err);
              }
            });
          } else {
            return cb(null, true);
          }
        };
      })(this);
      return this.parse.find("Card", {
        squishleId: doc.guid
      }, (function(_this) {
        return function(err, res) {
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
              return _this.parse.insert("Card", {
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
        };
      })(this));
    };

    PeggParse.prototype._insertChoice = function(cardId, doc, index, cb) {
      var cardPointer, img, txt;
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
        return this.parse.find("Choice", {
          card: cardPointer
        }, (function(_this) {
          return function(err, res) {
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
                return _this.parse.insert("Choice", {
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
          };
        })(this));
      }
    };

    PeggParse.prototype._insertCategory = function(cat, cb) {
      return this.parse.find("Category", {
        name: cat.name
      }, (function(_this) {
        return function(err, res) {
          if (err) {
            return cb(err);
          } else {
            if (res.results.length > 0) {
              return cb(null, res.results[0].objectId);
            } else {
              return _this.parse.insert("Category", {
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
        };
      })(this));
    };

    PeggParse.prototype._insertCardCategory = function(cardId, categoryId, cb) {
      var cardPointer, categoryPointer;
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
      return this.parse.find("CardCategory", {
        card: cardPointer,
        category: categoryPointer
      }, (function(_this) {
        return function(err, res) {
          if (err) {
            return cb(err);
          } else {
            if (res.results.length > 0) {
              return cb(null, res.results[0].objectId);
            } else {
              return _this.parse.insert("CardCategory", {
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
        };
      })(this));
    };

    return PeggParse;

  })();

  module.exports = PeggParse;

}).call(this);
