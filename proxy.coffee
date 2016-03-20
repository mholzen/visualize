uris = require './uris'
wreck = require 'wreck'

proxy = (request, reply, callback)->
  reply.proxy
    uri: uris.addScheme request
    onResponse: (err, response, request, reply, settings, ttl)->
      callback err, response, request, reply, settings, ttl

proxyPayload = (request, reply, callback)->
  reply.proxy
    uri: uris.addScheme request
    onResponse: (err, response, request, reply, settings, ttl)->
      if err
        reply err
      wreck.read response, null, (err, payload)->
        if err
          reply err
        callback err, response, payload, request, reply, settings, ttl


module.exports =
  proxy: proxy
  proxyPayload: proxyPayload
