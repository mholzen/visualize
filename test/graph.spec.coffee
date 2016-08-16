{Graph, rdf, Parser} = require '../libs/graph'
it 'should build triples', ->
  n = new rdf.NamedNode 'n'
  t = new rdf.Triple n, n, n
  console.log t.toString()

it 'should build graphs', ->
  g = new Graph()
  g.add 'a', 'b', 'c'
  console.log g.toRDF()

it 'should parse trig', ->
  p = new Parser()
  g.add 'a', 'b', 'c'
  console.log g.toRDF()
