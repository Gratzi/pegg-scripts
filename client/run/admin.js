(function() {
  var Admin, request,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  request = window.superagent;

  Admin = (function() {
    function Admin() {
      this.resetUser = __bind(this.resetUser, this);
    }

    Admin.prototype.resetUser = function(userId) {
      return 'asdf';
    };

    return Admin;

  })();

  window.admin = new Admin;

  $(document).ready(function() {
    return $('#resetUser_submit').on('click', function() {
      var userId;
      userId = $('#resetUser_id').val();
      return request.get("/users/reset/" + userId).end(function(res) {
        console.log(res);
        return null;
      });
    });
  });

}).call(this);
