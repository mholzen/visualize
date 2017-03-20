log = require '../log'

routes = []

fs = require 'fs'
csvparse = require '../libs/csv-parse'
graph = require '../libs/graph'
Path = require 'path'

{proxy, proxyPayload} = require '../proxy'

toGraph = (response, reply)->
  type = response.headers['content-type']
  switch
    when type.startsWith 'text/csv'
      parser = csvparse()
      mapper = new graph.MatrixGraphMapper
      stream = response.pipe(parser).pipe(mapper)
      stream.on 'finish', ->
        # With root
        # mapper.graph.add 'root', 'label', 'root'
        # mapper.graph.subjects().forEach (subject)->
        #   mapper.graph.add 'root', 'link', subject
        reply mapper.graph

    when type.startsWith 'text/plain'
      wreck.read response, null, (err, payload)->
        if err
          reply err
        result = new graph.Graph()
        payload.toString().match(/[^\r\n]+/g)
        .forEach (line, i)->
          result.add i, 'label', new graph.rdf.Literal line
        reply result

    when type.startsWith('text/turtle') or type.startsWith('application/octet-stream')
      wreck.read response, null, (err, payload)->
        if err
          reply err
        result = new graph.Graph()
        parser = new graph.Parser()
        parser.parse payload.toString(), (error, triple, prefixes)->
          if error
            log.debug error
            reply error
          else if triple
            result.add triple
          else
            reply result

    when type.startsWith 'text/html'
      wreck.read response, null, (err, payload)->
        if err
          reply err
        html = marked( payload.toString() )
        $ = cheerio.load html
        reply graph.toGraph $


    else
      reply "cannot convert '#{type}' to graph"


routes.push
  method: 'GET'
  path: '/graph/{uri*}'
  config:
    handler: (request, reply) ->
      request.params.uri = 'prefix:ttl/' + request.params.uri
      proxy request, reply, (err, response, request, reply)->
        toGraph response, (g)->
          if g instanceof graph.Graph
            # reply g.toJSON()
            reply(g.toRDF()).type('text/rdf')
          else
            reply(g.message).code(500)


wreck = require 'wreck'
marked = require 'marked'
cheerio = require 'cheerio'


routes.push
  method: 'GET'
  path: '/nodes-edges/{uri*}'
  config:
    handler: (request, reply) ->
      request.params.uri = 'prefix:ttl/' + request.params.uri
      proxy request, reply, (err, response, request, reply)->
        toGraph response, (g)->
          if g instanceof graph.Graph
            reply g.toNodesEdges()
          else
            reply(g.message).code(500)

routes.push
  method: 'GET'
  path: '/rdf/{uri*}'
  config:
    handler: (request, reply) ->
      request.params.uri = '/prefix:ttl/' + request.params.uri
      proxy request, reply, (err, response)->
        toGraph response, (g)->
          if g instanceof graph.Graph
            t = g.rdfGraph.toArray().map (t)->
              t.toString()
            reply t.join('')
          else
            reply(g).code(404) # error


routes.push
  method: 'GET'
  path: '/force-directed/{uri*}'
  config:
    handler: (request, reply) ->
      request.params.uri = 'graph/' + request.params.uri
      proxy request, reply, (err, response)->
        reply.view 'force-directed',
          uri: request.params.uri,

routes.push
  method: 'GET'
  path: '/visjs/{uri*}'
  config:
    handler: (request, reply) ->
      request.params.uri = '/nodes-edges/' + request.params.uri
      reply.view 'visjs',
        uri: request.params.uri,

module.exports = routes
