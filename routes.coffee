routes = []

routes.push
  method: 'GET',
  path: '/'
  handler: (request, reply)->
    reply.redirect '/html/files/index'

routes.push
  method: 'GET',
  path: '/files/{param*}',
  # should handle .cson extensions
  handler:
    directory:
      path: 'files'
      listing: true

fs = require 'fs'
csvparse = require 'csv-parse'
graph = require './libs/graph'
Path = require 'path'

routes.push
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

routes.push
  method: 'GET'
  path: '/graph-from-html/{uri*}'
  handler: (request, reply) ->
    reply.proxy
      uri: 'http://' + request.info.host + '/' + request.params.uri,
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, null, (err, payload)->
          html = marked( payload.toString() )
          $ = cheerio.load html
          g = graph.toGraph $
          reply g.toJSON()


routes.push
  method: 'GET'
  path: '/force-directed/{uri*}'
  handler: (request, reply) ->
    reply.view 'force-directed',
      uri: request.params.uri,

routes.push
  method: 'GET'
  path: '/html/{uri*}'
  handler: (request, reply) ->
    reply.proxy
      uri: 'http://' + request.info.host + '/' + request.params.uri,
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, null, (err, payload)->
          console.log res.headers['content-type']
          if res.headers['content-type'].startsWith 'application/json'
            payload = JSON.parse payload.toString()
            if payload instanceof Array
              s = '<table><tr>'
              s += payload.map((item)-> '<td>'+item+'</td>').join('')
              s += '</tr></table>'
              reply s
            else
              reply payload.toString()
          else
            reply marked( payload.toString() )

routes.push
  method: 'GET'
  path: '/csv2json/{uri*}'
  handler: (request, reply) ->
    reply.proxy
      uri: 'http://' + request.info.host + '/' + request.params.uri,
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, null, (err, payload)->
          csvparse payload.toString(), {columns: true}, (err, output)->
            reply output


routes.push
  method: 'GET'
  path: '/chart/{uri*}'
  handler: (request, reply) ->
    reply.proxy
      uri: 'http://' + request.info.host + '/' + request.params.uri,
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, null, (err, payload)->
          reply.view 'chart',
            uri: request.params.uri
            content: payload.toString()

routes.push require './slideshow'

routes.push require './templates'

routes.push require './filters'

routes.push require './rdf'

routes.push require './maps'

module.exports = routes
