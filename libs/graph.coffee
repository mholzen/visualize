rdf = require 'rdf'
# consider json-ld (https://www.npmjs.com/package/jsonld)

Object.values = (obj) -> Object.keys(obj).map (key)-> obj[key]

class Graph
  constructor: (from)->
    if from instanceof rdf.Graph
      @rdfGraph = from
    else
      @rdfGraph = new rdf.Graph()

  add: (s,p,o)->
    if s? and not p? and not o?
      p = s.predicate
      o = s.object
      s = s.subject

    if typeof s == 'string'
      s = new rdf.NamedNode(s)

    if typeof p == 'string'
      p = new rdf.NamedNode(p)

    if typeof o == 'number'
      o = '"' + o.toString() + '"'

    if typeof o == 'string'
      o = if o.startsWith '"' then new rdf.Literal(o) else new rdf.NamedNode(o)

    triple = new rdf.Triple s, p, o
    @rdfGraph.add triple

  subjects: ()->
    return Object.keys @rdfGraph.indexSOP

  objects: (subjects, predicates)->
    triples = @rdfGraph.match subjects, predicates, null
    return triples.map (triple)->
      return triple.object

  nodes: ()->
    nodes = {}
    @rdfGraph.forEach (triple)->
      nodes[triple.subject] = nodes[triple.subject] or
          uri: triple.subject.toString()
      if not (triple.object instanceof rdf.Literal)
        nodes[triple.object] = nodes[triple.object] or
          uri: triple.object.toString()
      nodes[triple.subject][triple.predicate] = triple.object.toString()
    return nodes

  # ids: ()->
  #   nodes = @nodes()
  #   Object.keys(nodes).map (key)->nodes[key]

  removeMatches: (subjects, predicates, objects, limit)->
    return @rdfGraph.removeMatches subjects, predicates, objects, limit

  collapseEmptyNodes: ()->
    # find nodes that are empty
    # and have only two vertices
    return null

  toRDF: ->
    @rdfGraph.toArray().map (t)->t.toString()
    .join '\n'

  toJSON: ->
    nodes = {}
    @rdfGraph.forEach (triple)->
      nodes[triple.subject] = nodes[triple.subject] || {}
      nodes[triple.subject][triple.predicate] = triple.object.toString()

    vals = Object.keys(nodes).map((key)->nodes[key])

    links = []
    @rdfGraph.forEach (triple)->
      if nodes[triple.object]?
        links.push
          source: vals.indexOf nodes[triple.subject]
          target: vals.indexOf nodes[triple.object]

    return {
      nodes: vals
      links: links
    }

  toNodesEdges: ->
    nodes = @nodes()
    ids = Object.values nodes
    ids.forEach (node, id)->
      node.id = id

    edges = []
    @rdfGraph.forEach (triple)->
      console.log triple.object, triple.object instanceof rdf.Literal
      if not (triple.object instanceof rdf.Literal)
        edges.push
          from: ids.indexOf nodes[triple.subject]
          to: ids.indexOf nodes[triple.object]
          label: triple.predicate.toString()

    return {
      nodes: ids
      edges: edges
    }



stream = require 'stream'

class MatrixGraphMapper extends stream.Writable
  constructor: ->
    super
      objectMode: true
    @graph = new Graph()
    @line = 0

  _write: (data, encoding, cb)->
    s = new rdf.BlankNode()
    for k,v of data
      #@graph.add @line, k, v
      if k == 'label'     # heuristic
        v = new rdf.Literal v
      @graph.add s, k, v
    @graph.add s, 'line', @line
    # @graph.add s, 'is', ''

    @line++
    cb()

class MapWithDefault
  constructor: (def)->
    @_map = new Map()
    @def = def

  getOrSet: (key)->
    if @_map.has key
      return @_map.get key
    value = @def()
    @_map.set key, value
    return value

isInline = (element) ->
  return element.type == 'text' ||
    element.tag in ['li', 'b', 'span']

elementLabel = (element)->
  if element.type == 'text'
    return element.data.trim()
  else if element.type = 'tag'
    return element.name
  else
    return ''

addElement = (graph, element, nodes, dom)->
  node = nodes.getOrSet element

  if isInline(element)
    parentNode = nodes.getOrSet element.parent
    labels = graph.objects parentNode, 'label'
    label = labels.join()
    label += elementLabel element
    graph.removeMatches parentNode, label
    graph.add parentNode, 'label', label

  else if element.parent
    parentNode = nodes.getOrSet element.parent
    graph.add parentNode, 'contains', node

  return if !element.children
  if typeof element.children == 'function'
    children = element.children()
  else
    children = element.children

  i = 0
  while i < children.length
    addElement graph, children[i], nodes, dom
    i++

toGraph = (from)->
  graph = new Graph from
  if typeof(from.root) != 'undefined'
    nodes = new MapWithDefault ->
      return new rdf.BlankNode()
    element = from.root()
    addElement graph, element, nodes, dom
  return graph

n3 = require 'n3'
Parser = n3.Parser

module.exports =
  Graph: Graph
  MatrixGraphMapper: MatrixGraphMapper
  toGraph: toGraph
  rdf: rdf
  Parser: Parser
