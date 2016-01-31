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
# routes.push
#   method: 'GET'
#   path: '/maps/{name}/{uri*}'
#   handler: (request, reply) ->
#     uri =
#     filter = filters[request.params.name]
#     if not filter
#       reply 404
#     wreck.get uri, (err, response, payload)->
#       if err
#         reply err
#       reply filter payload, response

module.exports = routes
