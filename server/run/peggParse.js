(function() {
  var Parse, PeggParse, fs;

  fs = require('fs');

  Parse = require('node-parse-api').Parse;

  PeggParse = (function() {
    function PeggParse(appId, masterKey) {
      this._parse = new Parse(appId, masterKey);
    }

    PeggParse.prototype.resetUser = function(userId, cb) {
      var failure, success, user;
      user = {
        __type: "Pointer",
        className: "_User",
        objectId: userId
      };
      this._parse.find('Pref', {
        user: user
      }, (function(_this) {
        return function(err, data) {
          var row, _i, _len, _ref, _results;
          console.log(data);
          _ref = data.results;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            row = _ref[_i];
            _results.push(_this._parse["delete"]('Pref', row.objectId, function(err, data) {
              return console.log(data);
            }));
          }
          return _results;
        };
      })(this));
      success = {
        message: "Success! User " + userId + " is fresh like spring pheasant"
      };
      failure = {
        message: "FAIL!!! BOOOO!!!! OMGWTFBBQ"
      };
      return cb(success, 200);
    };

    PeggParse.prototype.getTable = function(type, cb) {
      return this.getRows(type, 50, 0, [], function(items) {
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
            return _this.getRows(type, limit, skip + limit, res, cb);
          } else {
            return cb(res);
          }
        };
      })(this));
    };

    PeggParse.prototype.updateRow = function(type, id, json, cb) {
      return this._parse.update(type, id, json, function(err, data) {
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
