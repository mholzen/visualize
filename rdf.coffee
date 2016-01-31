rdf = require 'rdf'
uris = require './uris'
wreck = require 'wreck'

turtleParser = new rdf.TurtleParser

toJSON = (graph)->
  nodes = {}
  graph.forEach (triple)->
    nodes[triple.subject] = nodes[triple.subject] || {}
    nodes[triple.subject][triple.predicate] = triple.object.toString()

  vals = Object.keys(nodes).map((key)->nodes[key])

  links = []
  graph.forEach (triple)->
    if nodes[triple.object]?
      links.push
        source: vals.indexOf nodes[triple.subject]
        target: vals.indexOf nodes[triple.object]

  return {
    nodes: vals
    links: links
  }


module.exports =
  method: 'GET'
  path: '/rdf/{uri*}'
  handler: (request, reply) ->
    uri = uris.addScheme request
    wreck.get uri, (err, response, payload)->
      if err
        reply err
      turtleParser.parse payload, (graph)->
        reply toJSON graph
