var walk  = require('walk');
var files = [];

// Walker options
var walker  = walk.walk('./run', { followLinks: false });

walker.on('file', function(root, stat, next) {
    // Add this file to the list of files
    if(stat.name.indexOf('.js') > 0)
        files.push(root + '/' + stat.name);
    next();
});

walker.on('end', function() {
    console.log(files);
});