(function() {
  var PeggParse, fs, pp;

  fs = require('fs');

  PeggParse = require('./pegg-parse');

  pp = new PeggParse(config);

  module.exports = {
    getTable: function(type) {
      return this.getRows(type, 5, 0, [], function(items) {
        var filename, item, matches, _i, _len;
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          matches = item.url.match(/[^\/]+(#|\?|$)/);
          filename = "_" + item.id + "." + matches[0];
          console.log("" + item.id + ", " + filename);
        }
        return items;
      });
    },
    getRows: function(type, limit, skip, res, cb) {
      return pp.getRows(type, limit, skip, (function(_this) {
        return function(err, data) {
          if (data.results.length > 0) {
            return cb(data.results);
          } else {
            return cb(res);
          }
        };
      })(this));
    },
    updateRow: function(type, column, id, cb) {
      return pp.updateRow(type, column, id, function(err, data) {
        if (err != null) {
          return cb(err);
        } else {
          return cb(data);
        }
      });
    }
  };

}).call(this);
