module.exports =
  method: 'GET'
  path: '/slideshow/{uri*}'
  handler: (request, reply) ->
    reply.view 'slideshow',
      uri: request.params.uri

wreck = require 'wreck'

module.exports =
  method: 'GET'
  path: '/slideshow/{uri*}'
  handler: (request, reply) ->
    uri = 'http://' + request.info.host + '/' + request.params.uri
    uri = 'https://www.reddit.com/r/CityPorn+EarthPorn+ExposurePorn+lakeporn+wallpaper+wallpapers+windowshots/.json?&after=&limit=25'
    # uri = 'https://www.reddit.com/r/nsfw/.json?&after=&limit=25'
    reply.proxy
      uri: uri
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, {json: true}, (err, payload)->
          images = payload.data.children.map (child)->child.data.url
          reply.view 'slideshow',
            uri: uri
            images: images
