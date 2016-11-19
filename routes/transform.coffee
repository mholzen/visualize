log = require '../log'

{proxy, proxyPayload} = require '../proxy'
csvparse = require 'csv-parse'
cheerio = require 'cheerio'
wreck = require 'wreck'
graph = require '../libs/graph'
stringify = require 'csv-stringify'
stream = require 'stream'
cson = require 'cson'
boom = require 'boom'
client = require 'request-promise'
uris = require '../uris'

transformers =
  transpose: (payload, response)->
    content = JSON.parse payload.toString()
    content = content.sort (a,b)-> (a.date_added < b.date_added)
    return content

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
      else
        reply(response).type('text/plain')

routes.push
  method: 'GET'
  path: '/json/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = response.headers['content-type']
      if type.startsWith('text/csv')
        csvparse payload.toString(), {columns: true}, (err, output)->
          reply output
      else if type.startsWith 'text/html'
        $ = cheerio.load payload.toString()
        if request.params.uri.endsWith '/'
          response =
            $('li')
              .map (i, el)->
                $(this).text()
              .get()
        else
          response = "should convert html to json"
        reply(JSON.stringify(response)).type('application/json')

      else if request.params.uri.endsWith '.cson'
        result = cson.parse payload.toString()
        if result instanceof Error
          # TODO: https://github.com/hapijs/boom#faq
          reply boom.badData result.message + result.toString()
        else
          reply result
      else if type.startsWith('application/json' ) or type.startsWith('application/octet-stream')
        # weird: parsing JSON then toString() in the response
        reply JSON.parse payload.toString()
      else
        reply("cannot convert #{type} to json").code(500)

routes.push
  method: 'GET'
  path: '/csv/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = response.headers['content-type']
      switch
        when type.startsWith('text/turtle')
          result = []
          parser = new graph.Parser()
          parser.parse payload.toString(), (error, triple, prefixes)->
            if error
              log.debug error
              reply error
            else if triple
              result.push [triple.subject, triple.predicate, triple.object]
            else
              reply(stringify(result)).type('text/csv')
        when type.startsWith('text/plain')
          # consider rerwite /type/csv
          reply(payload).type('text/csv')
        else
          reply "cannot transform #{type} to csv"


types =
  turtle: 'text/turtle'
  csv: 'text/csv'

routes.push
  method: 'GET'
  path: '/types:{type}/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = types[request.params.type] ? request.params.type
      reply(payload.toString()).type(type)

handler = (request, reply) ->
  proxyPayload request, reply, (err, response, payload)->
    type = types[request.params.type] ? request.params.type
    reply(payload.toString()).type(type)

routes.push
  method: 'GET'
  path: '/index/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = types[request.params.type] ? request.params.type
      reply(payload.toString()).type(type)


httpHandler = (method, request, reply)->
  client
    method: method
    uri: uris.addScheme request
  .then (response)->
    reply response
  .catch (error)->
    reply error

httpToStream = (method, request, stream)->
  client
    method: method
    uri: uris.addScheme request
  .then (response)->
    stream.write response
  .catch (error)->
    stream.write error


routes.push
  method: 'GET'
  path: '/http:{method}/{uri*}'
  handler: (request, reply) ->
    httpHandler request.params.method, request, reply


csvparse = require '../libs/csv-parse'
{Transform} = require 'stream'

routes.push
  method: 'GET'
  path: '/map/http:{method}/{uri*}'
  handler: (request, reply) ->
    f = (uri, request, stream)->
      request.uri = uri
      httpHandler request.params.method, request, reply

    proxy request, reply, (err, response)->
      type = response?.headers['content-type']
      if type.startsWith 'text/csv'
        parser = csvparse()
        mapper = new Transform
          objectMode: true
          transform: (data, encoding, cb)->

            cb()
        reply(response.pipe(parser).pipe(mapper))
      else
        reply "cannot convert #{type} to iterator"

routes.push
  method: 'GET'
  path: '/prefix2:{path}/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      switch
        when type.startsWith('text/html')
          $ = cheerio.load payload.toString()
          $('a').each (i,elem)->
            $(this).attr('href', request.params.prefix + $(this).attr('href'))
          reply($.html())
        else
          reply "cannot prefix #{type}"

module.exports = routes
