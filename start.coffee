{Server} = require './server'

server = new Server
  rewrites: (path)->
    path.replace '/pretty/', '/templates/pretty.jade/'

server.start (err)->
  if err
    console.error err
  else
    console.log 'Server running at:', server.info.uri
