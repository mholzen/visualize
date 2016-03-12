{html} = require 'html'

it 'should', ->
  assert.equal
    html
      {name: '1', type: 'url', url: '2', x: '3'}
    ,
      '<a href="2">1</a><p'


it 'should', ->
  assert.equal
    dom
      {name: '1', type: 'url', url: '2', x: '3'}
  ,
    [{node: 'a', attr: [{href: '2'}]}]
