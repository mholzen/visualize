{filter} = require '../filters'

it 'should', ->
  filter ['a', 'b', 'c'], 'b'
  .should.equal ['b']
