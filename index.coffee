server = require './server'

server.start (err)->
  if err
    console.error err
  else
    console.log 'Server running at:', server.info.uri
