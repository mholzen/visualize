log.debug 'HERE1'
{Server} = require '../server'
log.debug 'HERE2'
request = require 'supertest'

server = new Server()
r = request(server.listener)

describe 'transform', ()->

  it 'should apply a function to a response', ()->
    r.get('/transform.expand/literals:www.marcvh.org')
    .expect(200)
    .then (response)->
      expect(response.text).equal('http://www.marcvh.org')

  it 'should transform a post request', ()->
    r.post('/transform.expand')
    .type('text/plain')
    .send('www.marcvh.org')
    .then (response)->
      expect(response.text).equal('http://www.marcvh.org')

  it 'should count a function to a response', ()->
    r.get('/count/files/samples/csv.csv')
    .expect(200)
    .then (response)->
      expect(response.text).equal('3')

  it 'should count from a post', ()->
    r.post('/count')
    .type('text/csv')
    .send('a\na\na\na\na\na\n')
    .expect(200)
    .then (response)->
      expect(response.text).equal('6')

describe 'http', ()->
  it 'should accept a uri', ()->
    r.get('/http.head/files/samples/uri.txt')
    .expect(200)
    .then (response)->
      expect(response.text).equal('6')
