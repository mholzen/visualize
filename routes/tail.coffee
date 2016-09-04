{proxy, proxyPayload} = require '../proxy'

log = require '../log'
_ = require 'lodash'
Queue = require '../libs/Queue'

csvparse = require 'csv-parse'
stringify = require 'csv-stringify'
{Transform, Readable} = require 'stream'

toTail = (count, response, reply)->
  type = response.headers['content-type']
  switch
    when type.startsWith 'text/csv'
      parser = csvparse
        columns: true
        relax_column_count: true

      header = null
      queue = new Queue()
      tailer = new Transform
        objectMode: true
        transform: (datax, encoding, cb)->
          queue.enqueue data
          if queue.getLength() > count
            queue.dequeue()
          cb()
        flush: (cb)->
          if parser.options.columns
            this.push parser.options.columns
          while not queue.isEmpty()
            this.push queue.dequeue()
          cb()

      reply response.pipe(parser).pipe(tailer).pipe(stringify())    # should output header

    else
      reply "cannot convert '#{type}' to graph"


routes = []
routes.push
  method: 'GET'
  path: '/tail:{count?}/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      count = if request.params.count? then request.params.count else 10
      toTail count, response, (g)->
        if g instanceof Readable
          reply(g).type(response.headers['content-type'])   # TODO: could be in proxy?
        else
          reply(g).code(404) # error

module.exports = routes
