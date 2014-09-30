(function() {
  var Parse, PeggParse, fs;

  fs = require('fs');

  Parse = require('node-parse-api').Parse;

  PeggParse = (function() {
    function PeggParse(appId, masterKey) {
      this._parse = new Parse(appId, masterKey);
    }

    PeggParse.prototype.resetUser = function(userId) {
      return "OK I'll reset user " + userId;
    };

    PeggParse.prototype.getTable = function(type, cb) {
      return this.getRows(type, 5, 0, [], function(items) {
        return cb(items);
      });
    };

    PeggParse.prototype.getRows = function(type, limit, skip, res, cb) {
      return this._parse.findMany(type, "?limit=" + limit + "&skip=" + skip, (function(_this) {
        return function(err, data) {
          var item, _i, _len, _ref;
          if ((data != null) && (data.results != null) && data.results.length > 0) {
            _ref = data.results;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              item = _ref[_i];
              res.push(item);
            }
            return cb(res);
          } else {
            return cb(res);
          }
        };
      })(this));
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
