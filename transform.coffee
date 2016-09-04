{proxy, proxyPayload} = require './proxy'

csvparse = require 'csv-parse'
cheerio = require 'cheerio'
wreck = require 'wreck'

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
      if type.startsWith 'application/octet-stream'
        reply(response).type('text/plain')
      else if type.startsWith 'text/html'
        wreck.read response, null, (err, payload)->
          if err
            return reply err
          $ = cheerio.load payload.toString()
          reply($.root().text()).type('text/plain')

routes.push
  method: 'GET'
  path: '/json/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = response.headers['content-type']
      if type.startsWith 'text/csv'
        csvparse payload.toString(), {columns: true}, (err, output)->
          reply output
      else if request.params.uri.endsWith '.cson'
        result = cson.parse payload.toString()
        if result instanceof Error
          # TODO: https://github.com/hapijs/boom#faq
          reply boom.badData result.message + result.toString()
        else
          reply result
      else
        # weird: parsing JSON then toString() in the response
        reply JSON.parse payload.toString()

module.exports = routes
