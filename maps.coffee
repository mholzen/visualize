{proxy, proxyPayload} = require './proxy'

routes = []

{Parser} = require 'htmlparser2'
{Writable} = require 'stream'
wreck = require 'wreck'

routes.push
  method: 'GET'
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
  path: '/json/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      log.debug response.headers 'content-type'
      if request.params.uri.endsWith '.cson'
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
