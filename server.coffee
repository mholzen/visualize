Hapi = require 'hapi'

server = new Hapi.Server()

server.connection
  port: 8000

Path = require 'path'

server.views
  engines:
    html: require 'handlebars'
  path: Path.join __dirname, 'templates'

server.route
  method: 'GET'
  path: '/force-directed/{uri*}'
  handler: (request, reply) ->
    reply.view 'force-directed',
      uri: request.params.uri

server.route
  method: 'GET',
  path: '/static/{param*}',
  handler:
    directory:
      path: 'static'

server.start ()->
  console.log('Server running at:', server.info.uri)
