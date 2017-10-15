log = require '../log'
{search, createQuery} = require 'search'
{Transform} = require 'stream'

routes = []

routes.push
  method: 'GET'
  path: '/search'
  config:
    handler: (request, reply) ->
      query = createQuery request.query
      results = search query
      stream = new Transform
        readableObjectMode: false
        writableObjectMode: true
        transform: (chunk, encoding, callback)->
          this.push JSON.stringify(chunk) + '\n'
          callback()

      results.pipe stream
      reply(stream).type('application/json')

module.exports = routes
