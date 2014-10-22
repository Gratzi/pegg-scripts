(function() {
  var Admin, request,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  request = window.superagent;

  Admin = (function() {
    function Admin() {
      this.resetUser = __bind(this.resetUser, this);
    }

    Admin.prototype.resetUser = function(userId, cb) {
      return request.get("/users/reset/" + userId).set('Accept', 'application/json').end(function(res) {
        res.json = res.body;
        console.log(res.json, res.status);
        if (cb != null) {
          return cb(res);
        }
      });
    };

    return Admin;

  })();

  window.admin = new Admin;

  $(document).ready(function() {
    var _resetUserSubmit;
    _resetUserSubmit = (function(_this) {
      return function() {
        var userId;
        $('#resetUser_message').html("...").parent().removeClass('has-success').removeClass('has-error');
        userId = $('#resetUser_id').val();
        return window.admin.resetUser(userId, function(res) {
          var _ref, _ref1;
          if (res.status === 200) {
            $('#resetUser_message').html(res.json.message).parent().addClass('has-success');
            return $('#resetUser_detail').html(JSON.stringify(res.json.results));
          } else {
            $('#resetUser_message').html(((_ref = res.json) != null ? _ref.message : void 0) || res.error).parent().addClass('has-error');
            return $('#resetUser_detail').html(JSON.stringify(((_ref1 = res.json) != null ? _ref1.error : void 0) || res.error));
          }
        });
      };
    })(this);
    return $('#resetUser').on('submit', function() {
      _resetUserSubmit();
      return false;
    });
  });

}).call(this);
