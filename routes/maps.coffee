{proxy, proxyPayload} = require '../proxy'
log = require '../log'

routes = []

{Parser} = require 'htmlparser2'
{Writable, Transform} = require 'stream'
{toObjectStream} = require '../libs/stream'
wreck = require 'wreck'
uris = require '../uris'

routes.push
  method: 'GET'
  # map of href's in a collection
  path: '/prefix:{prefix}/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, res, request, reply, settings, ttl)->
      response = ''
      parser = new Parser({
        onopentag: (name, attribs) ->
          response += '<'+name+' '
          if name == 'a'
            attribs.href = '/' + request.params.prefix + attribs.href
          response += "#{key}=\"#{value}\" "for key, value of attribs
          response += '>'
        ontext: (text)->
          response += text
        onclosetag: (name)->
          response += '</'+name+'>'
      }, decodeEntities: true)

      wreck.read res, null, (err, payload)->
        parser.write payload.toString()
        parser.end()
        reply null, response

# maps by name
cson = require 'cson'
boom = require 'boom'



routes.push
  method: 'GET'
  path: '/balance/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = response.headers['content-type']
      if not type.startsWith 'application/json'
        return reply('need json').code(400)
      payload = JSON.parse payload
      payload.forEach (item)->item['_Date']=Date.parse(item['Date'])
      # payload = payload.sort (a,b)->Date.compare(Date.parse(a['Date']),Date.parse(b['Date']))
      payload = payload.sort (a,b)->Date.compare(a['_Date'],b['_Date'])
      AmountTotal = 0.0
      payload.forEach (item)->
        Amount = parseFloat(item['Amount'])
        AmountTotal += if item['Transaction Type'] == 'credit' then Amount else -Amount
        item['AmountTotal'] = AmountTotal
      reply(payload)

# fsp = require 'fs-promise'
#
# routes.push
#   method: 'GET'
#   path: '/augment:files/{uri*}'
#   handler: (request, reply) ->
#     proxyJson request, reply, (err, response, payload)->
#       if not payload instanceof Array
#         reply('cannot augment non array type').type(500)
#
#       Promises.all
#         payload.map (item)->
#           fsp.stat('files/'+item)
#           .then (response)->1
#           .catch (err)->0
#       .forEach (response)->


rp = require 'request-promise'
routes.push
  method: 'GET'
  path: '/map:{function}/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      stream = toObjectStream response

      mapper = new Transform
        readableObjectMode: false
        writableObjectMode: true
        transform: (data, encoding, cb)->
          url = '/' + request.params.function
          url = uris.expand url, request.info.host
          log.debug url: url, payload: data, 'posting'
          rp
            method: 'POST'
            uri: url
            body: JSON.stringify(data)
          .then (body)->
            log.debug body: body, 'received from post'
            cb(null, body + '\n')
          .catch (err)->
            log.error err: err, 'ERR'

      reply(stream.pipe(mapper)).type('text/csv')


module.exports = routes
