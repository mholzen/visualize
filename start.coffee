{Server} = require './server'
log = require './log'

server = new Server
  rewrites: (path)->
    path.replace '/pretty/', '/templates/pretty.jade/'

server.start (err)->
  if err
    log.error err
  else
    log.info 'Server running at:', server.info.uri
