routes = []

d = (a)->console.log 'HERE: ' + a

fs = require 'fs'
csvparse = require 'csv-parse'
graph = require '../libs/graph'
Path = require 'path'

{proxy, proxyPayload} = require '../proxy'

toGraph = (response, reply)->
  type = response.headers['content-type']
  switch
    when type.startsWith 'text/csv'
      parser = csvparse
        columns: true
      mapper = new graph.MatrixGraphMapper
      stream = response.pipe(parser).pipe(mapper)
      stream.on 'finish', ->
        mapper.graph.add 'root', 'label', 'root'
        mapper.graph.subjects().forEach (subject)->
          mapper.graph.add 'root', 'link', subject
        reply mapper.graph

    when type.startsWith 'text/turtle'
      wreck.read response, null, (err, payload)->
        if err
          reply err
        graph.parser.parse payload.toString(), (error, triples, prefixes)->
          if error
            reply(error).code(404)
          else
            reply graph.toGraph triples

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
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      type = response.headers['content-type']
      switch
        when type.startsWith 'text/csv'
          parser = csvparse
            columns: true
          mapper = new graph.MatrixGraphMapper
          stream = response.pipe(parser).pipe(mapper)
          stream.on 'finish', ->
            mapper.graph.add 'root', 'label', 'root'
            mapper.graph.subjects().forEach (subject)->
              mapper.graph.add 'root', 'link', subject
            reply mapper.graph.toJSON()

        when type.startsWith 'text/turtle'
          wreck.read response, null, (err, payload)->
            if err
              reply err
            turtleParser = new graph.rdf.TurtleParser
            turtleParser.parse payload, (graph)->
              if not graph?
                reply 'turtleParser error'
              else
                graph = toGraph graph
                reply graph.toJSON()
                response.graph = graph # trying to save the graph for other handlers

        when type.startsWith 'text/html'
          wreck.read response, null, (err, payload)->
            if err
              reply err
            html = marked( payload.toString() )
            $ = cheerio.load html
            g = graph.toGraph $
            reply g.toJSON()

        else
          reply "doesn't know how to convert #{type} to graph"


wreck = require 'wreck'
marked = require 'marked'
cheerio = require 'cheerio'


routes.push
  method: 'GET'
  path: '/graph-from-html/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      html = marked( payload.toString() )
      $ = cheerio.load html
      g = graph.toGraph $
      reply g.toJSON()


routes.push
  method: 'GET'
  path: '/nodes-edges/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      toGraph response, (g)->
        if g instanceof graph.Graph
          reply g.toNodesEdges()
        else
          reply(g).code(404) # error

routes.push
  method: 'GET'
  path: '/rdf/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      toGraph response, (g)->
        if g instanceof graph.Graph
          reply g.graph.toArray().map (t)->t.to
        else
          reply(g).code(404) # error


routes.push
  method: 'GET'
  path: '/force-directed/{uri*}'
  handler: (request, reply) ->
    request.params.uri = 'graph/' + request.params.uri
    proxy request, reply, (err, response)->
      reply.view 'force-directed',
        uri: request.params.uri,

routes.push
  method: 'GET'
  path: '/visjs/{uri*}'
  handler: (request, reply) ->
    request.params.uri = '/nodes-edges/' + request.params.uri
    reply.view 'visjs',
      uri: request.params.uri,

module.exports = routes
