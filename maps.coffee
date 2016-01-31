uris = require './uris'

routes = []

{Parser} = require 'htmlparser2'
{Writable} = require 'stream'
wreck = require 'wreck'

routes.push
  method: 'GET'
  path: '/prefix:{prefix}/{uri*}'
  handler: (request, reply) ->
    reply.proxy
      uri: uris.addScheme request
      onResponse: (err, res, request, reply, settings, ttl)->
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

routes.push
  method: 'GET'
  path: '/json/{uri*}'
  handler: (request, reply) ->
    reply.proxy
      uri: uris.addScheme request
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, null, (err, payload)->
          if err
            reply err
          if request.params.uri.endsWith '.cson'
            reply cson.parse payload.toString()
          else
            # weird: parsing JSON then toString() in the response
            reply JSON.parse payload.toString()

module.exports = routes
