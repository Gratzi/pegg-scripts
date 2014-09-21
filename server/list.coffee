walk = require 'walk'

module.exports =

  serverScripts: (res) ->
    files = []

    # Walker options
    walker = walk.walk "./server/run", followLinks: false

    walker.on "file", (root, stat, next) ->
      # Add this file to the list of files
      files.push root + "/" + stat.name  if stat.name.indexOf(".js") > 0
      next()

    walker.on "end", ->
      res.send files
