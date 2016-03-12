uris = require './uris'
wreck = require 'wreck'

proxy = (request, reply, callback)->
  reply.proxy
    uri: uris.addScheme request
    onResponse: (err, res, request, reply, settings, ttl)->
      wreck.read res, null, (err, payload)->
        if err
          reply err
        callback err, res, payload, request, reply, settings, ttl

module.exports = proxy
