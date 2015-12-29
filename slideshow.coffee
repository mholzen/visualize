module.exports =
  method: 'GET'
  path: '/slideshow/{uri*}'
  handler: (request, reply) ->
    reply.view 'slideshow',
      uri: request.params.uri

wreck = require 'wreck'


addScheme = (uri)->
  if uri.indexOf('http') != 0
     uri = 'http://' + request.info.host + '/' + request.params.uri
  return uri

module.exports =
  method: 'GET'
  path: '/slideshow/{uri*}'
  handler: (request, reply) ->
    uri = addScheme request.params.uri
    reply.proxy
      uri: uri
      onResponse: (err, res, request, reply, settings, ttl)->
        if err
          reply err
        wreck.read res, {json: true}, (err, payload)->
          if err
            return reply err
          images = payload.data.children.map (child)->child.data.url
          reply.view 'slideshow',
            uri: uri
            images: images
