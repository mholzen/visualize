uris = require './uris'
wreck = require 'wreck'

proxy = (request, reply, callback)->
  reply.proxy
    uri: uris.addScheme request
    onResponse: (err, response, request, reply, settings, ttl)->
      if response.statusCode == 404
        # how to augment the error with the uri?
        console.log "404 - " + request.params.uri
        return reply response
      console.log response.headers['content-type']
      callback err, response, request, reply, settings, ttl

proxyPayload = (request, reply, callback)->
  reply.proxy
    uri: uris.addScheme request
    onResponse: (err, response, request, reply, settings, ttl)->
      if err
        reply err
      if response.statusCode == 404
        response.url = request.uri
        return reply response
      wreck.read response, null, (err, payload)->
        if err
          reply err
        callback err, response, payload, request, reply, settings, ttl


module.exports =
  proxy: proxy
  proxyPayload: proxyPayload
