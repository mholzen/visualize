{proxy, proxyPayload} = require '../proxy'

log = require '../log'
_ = require 'lodash'

csvparse = require 'csv-parse'
stringify = require 'csv-stringify'
{Transform, Readable} = require 'stream'
wreck = require 'wreck'

toSlice = (slice, response, reply)->
  type = response.headers['content-type']
  switch
    when type.startsWith 'text/csv'
      parser = csvparse
        columns: true
        relax_column_count: true

      hasOutputHeader = false
      slicer = new Transform
        objectMode: true
        transform: (data, encoding, cb)->
          if not hasOutputHeader
            this.push [slice]
            hasOutputHeader = true
          data = _.pick data, slice
          this.push data
          cb()

      reply response.pipe(parser).pipe(slicer).pipe(stringify())    # should output header

    when type.startsWith 'application/json'
      wreck.read response, null, (err, payload)->
        content = JSON.parse payload.toString()
        slices = content.map (row)->
          if row instanceof Array
            row.slice slice
          else
            _.pick row, slice
        reply(JSON.stringify slices)

    else
      reply "cannot slice '#{type}'"


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
