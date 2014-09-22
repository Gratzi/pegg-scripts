(function() {
  var Parse, PeggParse, fs;

  fs = require('fs');

  Parse = require('node-parse-api').Parse;

  PeggParse = (function() {
    function PeggParse(appId, masterKey) {
      this._parse = new Parse(appId, masterKey);
    }

    PeggParse.prototype.getTable = function(type, cb) {
      return this.getRows(type, 5, 0, [], function(items) {
        return cb(items);
      });
    };

    PeggParse.prototype.getRows = function(type, limit, skip, res, cb) {
      return this._parse.findMany(type, "?limit=" + limit + "&skip=" + skip, function(err, data) {
        if (data.results.length > 0) {
          return cb(data.results);
        } else {
          return cb(res);
        }
      });
    };

    PeggParse.prototype.updateRow = function(type, column, id, cb) {
      return this._parse.updateRow(type, column, id, function(err, data) {
        if (err != null) {
          return cb(err);
        } else {
          return cb(data);
        }
      });
    };

    return PeggParse;

  })();

  module.exports = PeggParse;

}).call(this);
