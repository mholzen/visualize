Hapi = require 'hapi'

server = new Hapi.Server()

server.connection
  port: 8001

Path = require 'path'

server.views
  engines:
    html:
      module: require 'handlebars'
      isCached: false
    jade:
      module: require 'jade'
      isCached: false
  defaultExtension: 'html'
  path: Path.join __dirname, 'templates'

server.route
  method: 'GET',
  path: '/'
  handler: (request, reply)->
    reply.view 'prompt.jade'

server.route
  method: 'GET',
  path: '/static/{param*}',
  handler:
    directory:
      path: 'static'
      listing: true

fs = require 'fs'
csvparse = require 'csv-parse'
graph = require './libs/graph'

server.route
  method: 'GET'
  path: '/graph/{uri*}'
  handler: (request, reply) ->
    # should use content-type to determine next action
    input = fs.createReadStream Path.join __dirname, request.params.uri
    parser = csvparse
      columns: true
    mapper = new graph.MatrixGraphMapper
    stream = input.pipe(parser).pipe(mapper)
    stream.on 'finish', ->
      mapper.graph.add 'marc', 'label', 'Marc'
      mapper.graph.subjects().forEach (subject)->
        mapper.graph.add 'marc', 'link', subject
      reply mapper.graph.toJSON()

wreck = require 'wreck'
marked = require 'marked'
cheerio = require 'cheerio'

server.route
  method: 'GET'
  path: '/graph-from-html/{uri*}'
  handler: (request, reply) ->
    reply.proxy
      uri: server.info.protocol + '://' + server.info.host + ':' + server.info.port + '/'+request.params.uri,
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, null, (err, payload)->
          html = marked( payload.toString() )
          $ = cheerio.load html
          g = graph.toGraph $
          reply g.toJSON()


server.route
  method: 'GET'
  path: '/force-directed/{uri*}'
  handler: (request, reply) ->
    reply.view 'force-directed',
      uri: request.params.uri

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
  console.log 'Server running at:', server.info.uri
