log = require '../log'

{proxy, proxyPayload} = require '../proxy'
csvparse = require 'csv-parse'
# csvparse = require '../libs/csv-parse'
cheerio = require 'cheerio'
wreck = require 'wreck'
graph = require '../libs/graph'
stringify = require 'csv-stringify'
{Writable, Transform} = require 'stream'
cson = require 'cson'
boom = require 'boom'
client = require 'request-promise'
uris = require '../uris'
yaml = require 'yamljs'
{toObjectStream, toHighland} = require '../libs/stream'

{reducers, mappers, parse} = require '@vonholzen/transform'

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
      transpose = new Transform
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
      switch
        when type.startsWith('text/csv')
          csvparse payload.toString(), {columns: true}, (err, output)->
            if err
              reply err
            reply output
        when type.startsWith('text/html')
          $ = cheerio.load payload.toString()
          if request.params.uri.endsWith '/'
            response =
              $('li')
                .map (i, el)->$(this).text()
                .filter (i,v)-> v != 'Parent Directory'
                .get()
            reply(JSON.stringify(response)).type('application/json')
          else
            response = "should convert html to json"

        when type.startsWith('application/x-yaml')
          reply(yaml.parse(payload.toString())).type('application/json')

        when request.params.uri.endsWith '.cson'
          result = cson.parse payload.toString()
          if result instanceof Error
            # TODO: https://github.com/hapijs/boom#faq
            reply boom.badData result.message + result.toString()
          else
            reply result
        when type.startsWith('application/json' ) or type.startsWith('application/octet-stream')
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
  yaml: 'application/x-yaml'

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


# routes.push
#   method: 'GET'
#   path: '/http:{method}/{uri*}'
#   handler: (request, reply) ->
#     httpHandler request.params.method, request, reply

routes.push
  method: 'GET'
  path: '/http:{method}/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      request.params.uri = payload.toString()
      httpHandler request.params.method, request, reply

routes.push
  method: 'GET'
  path: '/prefix2:{path}/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = response?.headers['content-type']
      switch
        when type.startsWith('text/html')
          $ = cheerio.load payload.toString()
          $('a').each (i,elem)->
            $(this).attr('href', request.params.prefix + $(this).attr('href'))
          reply($.html())
        else
          reply "cannot prefix #{type}"

routes.push
  method: 'GET'
  path: '/prefix:ttl/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = response?.headers['content-type']
      if type.startsWith('text/turtle')
        reply("@prefix : <>.\n" + payload.toString()).type(response?.headers['content-type'])
      else
        # even though we are setting passThrough, because we are using an onResponse
        # we are not setting all headers on the response
        reply(payload.toString()).type(type)




routes.push
  method: 'GET'
  path: '/rewrite:prefix:{text}/{uri*}'
  handler: (request, reply) ->
    uri = request.params.text + request.params.uri
    request.params.uri = '/' + uri

    proxy request, reply, (err, response)->
      if err
        log.error err
        return reply err
      reply response


routes.push
  method: 'POST'
  path: '/transform.expand'
  handler: (request, reply) ->
    reply(uris.expand(request.payload))


routes.push
  method: 'GET'
  path: '/count/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      stream = toObjectStream response
      count = 0
      counter = new Writable
        objectMode: true
        write: (chunk, encoding, callback)->
          log.debug chunk:chunk, 'counted'
          count = count + 1
          callback()

      stream.pipe(counter)
      counter.on 'finish', ()->
        reply(count).type('text/plain')

routes.push
  method: 'POST'
  path: '/count'
  handler: (request, reply) ->
    log.debug payload: request.payload, 'received'
    stream = toObjectStream request
    stream.on 'error', (err)->
      log.debug count: count, 'responding'
      reply('parser error', err).code(500)

    count = 0
    counter = new Writable
      objectMode: true
      write: (chunk, encoding, callback)->
        log.debug chunk:chunk, 'counted'
        count = count + 1
        callback()

    stream.pipe(counter)

    counter.on 'finish', ()->
      log.debug count: count, 'responding'
      reply(count).type('text/plain')

routes.push
  method: 'GET'
  path: '/reducers'
  handler: (request, reply) ->
    reply JSON.stringify Object.keys reducers

routes.push
  method: 'GET'
  path: '/reducers/{reducer}/{uri*}'
  handler: (request, reply) ->
    # find reducer
    if not reducers[request.params.reducer]?
      return reply 404, 'cannot find reducer'
    [memo, reducer] = reducers[request.params.reducer]()
    proxy request, reply, (err, response)->
      s = toHighland(response)
      # s.each (x)->console.log x
      s.reduce(memo, reducer).toArray (memo)->
        reply memo

routes.push
  method: 'GET'
  path: '/mappers'
  handler: (request, reply) ->
    reply JSON.stringify Object.keys mappers

routes.push
  method: 'GET'
  path: '/mappers/{mapper}/{uri*}'
  handler: (request, reply) ->
    # find reducer
    if not mappers[request.params.mapper]?
      return reply 404, 'cannot find mapper'
    mapper = mappers[request.params.mapper]()
    proxy request, reply, (err, response)->
      s = toHighland(response)
      s.map(mapper).toArray (memo)->
        if not request.params.uri.endsWith '/'
          memo = memo.join '\n'
        reply memo

module.exports = routes
