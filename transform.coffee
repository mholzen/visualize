{proxy} = require './proxy'

csvparse = require 'csv-parse'

transformers =
  transpose: (payload, response)->
    content = JSON.parse payload.toString()
    content = content.sort (a,b)-> (a.date_added < b.date_added)
    return content


stringify = require 'csv-stringify'
stream = require 'stream'

routes = []
routes.push
  method: 'GET'
  path: '/transpose/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      if not (response.headers['content-type'].startsWith 'text/csv')
        reply 'needs csv'

      parser = csvparse   # TODO: use /csv/* route instead?
        columns: true

      content = []
      transpose = new stream.Transform
        objectMode: true
        transform: (chunk, encoding, done)->
          content.push chunk
          done()
        flush: (done)->
          transform = this
          parser.options.columns.map (col)=>
            transform.push content.map (row)->row[col]
          done()

      reply response.pipe(parser).pipe(transpose).pipe(stringify())
        .type('text/csv')

routes.push
  method: 'GET'
  path: '/text/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      type = response.headers['content-type']
      if type == 'application/octet-stream'
        response.headers['content-type'] = 'text/plain'
      reply response

module.exports = routes
