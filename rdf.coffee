{Graph, rdf} = require 'graph'
uris = require './uris'
wreck = require 'wreck'

turtleParser = new rdf.TurtleParser

module.exports =
  method: 'GET'
  path: '/rdf/{uri*}'
  handler: (request, reply) ->
    uri = uris.addScheme request
    wreck.get uri, (err, response, payload)->
      if err
        reply err
      turtleParser.parse payload, (graph)->
        graph = new Graph graph
        reply graph.toNodesEdges()
        # reply toJSON graph
