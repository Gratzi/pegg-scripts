(function() {
  var Parse, PeggParse, fs,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  fs = require('fs');

  Parse = require('node-parse-api').Parse;

  PeggParse = (function() {
    function PeggParse(appId, masterKey) {
      this._clearHasPegged = __bind(this._clearHasPegged, this);
      this._clearHasPreffed = __bind(this._clearHasPreffed, this);
      this.deletePeggs = __bind(this.deletePeggs, this);
      this.deletePrefs = __bind(this.deletePrefs, this);
      this._parse = new Parse(appId, masterKey);
    }

    PeggParse.prototype.resetUser = function(userId, cb) {
      var clearedHasPegged, clearedHasPreffed, deletedPeggs, deletedPrefs, user;
      user = {
        __type: "Pointer",
        className: "_User",
        objectId: userId
      };
      deletedPrefs = this.deletePrefs(user);
      deletedPeggs = this.deletePeggs(user);
      clearedHasPreffed = this.clearHasPreffed(userId);
      clearedHasPegged = this.clearHasPegged(userId);
      return Parse.Promise.when(deletedPrefs, deletedPeggs, clearedHasPreffed, clearedHasPegged);
    };

    PeggParse.prototype.deletePrefs = function(user) {
      return this._parse.find('Pref', {
        user: user
      }).then((function(_this) {
        return function(data) {
          var i, prefRowsDeleted, row, _i, _len, _ref;
          prefRowsDeleted = [];
          _ref = data.results;
          for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
            row = _ref[i];
            prefRowsDeleted[i] = _this._parse["delete"]('Pref', row.objectId);
          }
          return Parse.Promise.when(prefRowsDeleted);
        };
      })(this));
    };

    PeggParse.prototype.deletePeggs = function(user) {
      return this._parse.find('Pegg', {
        user: user
      }).then((function(_this) {
        return function(data) {
          var i, peggRowsDeleted, row, _i, _len, _ref;
          peggRowsDeleted = [];
          _ref = data.results;
          for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
            row = _ref[i];
            peggRowsDeleted[i] = _this._parse["delete"]('Pegg', row.objectId);
          }
          return Parse.Promise.when(peggRowsDeleted);
        };
      })(this));
    };

    PeggParse.prototype._clearHasPreffed = function(userId) {
      return this.getTable('Card').then((function(_this) {
        return function(results) {
          var i, preffedRowsCleared, row, _i, _len;
          preffedRowsCleared = [];
          for (i = _i = 0, _len = results.length; _i < _len; i = ++_i) {
            row = results[i];
            if ((row.hasPreffed != null) && row.hasPreffed.indexOf(userId) > -1) {
              row.hasPreffed.splice(userId, 1);
              preffedRowsCleared[i] = _this._parse.update('Card', row.objectId, row);
            }
          }
          return Parse.Promise.when(preffedRowsCleared);
        };
      })(this));
    };

    PeggParse.prototype._clearHasPegged = function(userId) {
      return this.getTable('Pref').then((function(_this) {
        return function(results) {
          var i, peggedRowsCleared, row, _i, _len;
          peggedRowsCleared = [];
          for (i = _i = 0, _len = results.length; _i < _len; i = ++_i) {
            row = results[i];
            if ((row.hasPegged != null) && row.hasPegged.indexOf(userId) > -1) {
              row.hasPegged.splice(userId, 1);
              peggedRowsCleared[i] = _this._parse.update('Pref', row.objectId, row);
            }
          }
          return Parse.Promise.when(peggedRowsCleared);
        };
      })(this));
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
