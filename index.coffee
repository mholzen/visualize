server = require './server'

server.start ()->
  console.log 'Server running at:', server.info.uri
