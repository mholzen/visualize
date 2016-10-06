wreck = require 'wreck'
uris = require '../uris'

module.exports =
  method: 'GET'
  path: '/slideshow/{uri*}'
  handler: (request, reply) ->
    if request.query.from
      uri = request.query.from
    else
     uri = uris.addScheme request
    if not uri
      return reply.view 'slideshow'

    reply.proxy
      uri: uri
      onResponse: (err, res, request, reply, settings, ttl)->
        if err
          reply err

        # extract images from URL
        # '/select/images/...'

        wreck.read res, {json: true}, (err, payload)->
          if err
            return reply err
          images = payload.data.children.map (child)->child.data.url
          reply.view 'slideshow',
            uri: uri
            images: images
