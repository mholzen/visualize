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
  method: 'GET',
  path: '/static/{param*}',
  handler:
    directory:
      path: 'static'

fs = require 'fs'
parse = require 'csv-parse'
graph = require '../graph'

server.route
  method: 'GET'
  path: '/graph/{uri*}'
  handler: (request, reply) ->
    input = fs.createReadStream Path.join __dirname, request.params.uri
    parser = parse()
    mapper = new graph.MatrixGraphMapper()
    stream = input.pipe(parser).pipe(mapper)
    stream.on 'finish', ->
      graph = mapper.graph
      reply graph.toJSON()

server.route
  method: 'GET'
  path: '/force-directed/{uri*}'
  handler: (request, reply) ->
    reply.view 'force-directed',
      uri: request.params.uri

marked = require 'marked'
wreck = require 'wreck'

server.route
  method: 'GET'
  path: '/html/{uri*}'
  handler: (request, reply) ->
    reply.proxy
      uri: server.info.protocol + '://' + server.info.host + ':' + server.info.port + '/'+request.params.uri,
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, null, (err, payload)->
          reply marked( payload.toString() )

server.start ()->
  console.log('Server running at:', server.info.uri)
