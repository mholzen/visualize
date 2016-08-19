{proxy, proxyPayload} = require '../proxy'

log = require '../log'
_ = require 'lodash'

csvparse = require 'csv-parse'
stringify = require 'csv-stringify'
{Transform, Readable} = require 'stream'


toSlice = (slice, response, reply)->
  type = response.headers['content-type']
  switch
    when type.startsWith 'text/csv'
      parser = csvparse
        columns: true
        relax_column_count: true

      slicer = new Transform
        objectMode: true
        transform: (data, encoding, cb)->
          console.log data
          data = _.pick data, slice
          this.push data
          cb()

      reply response.pipe(parser).pipe(slicer).pipe(stringify())    # should output header

    else
      reply "cannot convert '#{type}' to graph"


routes = []
routes.push
  method: 'GET'
  path: '/slice/{slice}/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      toSlice request.params.slice, response, (g)->
        if g instanceof Readable
          reply(g).type(response.headers['content-type'])   # TODO: could be in proxy?
        else
          reply(g).code(404) # error

module.exports = routes
