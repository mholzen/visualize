uris = require './uris'
wreck = require 'wreck'
log = require './log'

# TODO: does not support redirects

proxy = (request, reply, callback)->
  reply.proxy
    uri: uris.addScheme request
    passThrough: true
    acceptEncoding: false
    localStatePassThrough: true
    onResponse: (err, response, request, reply, settings, ttl)->
      log.debug {err: err, stausCode: response.statusCode}, 'received'
      if response.statusCode == 404
        # how to augment the error with the uri?
        console.log "404 - " + request.params.uri
        return reply response
      console.log response.headers['content-type']
      callback err, response, request, reply, settings, ttl

proxyPayload = (request, reply, callback)->
  uri = uris.addScheme request
  log.debug 'proxy request', {uri}
  reply.proxy
    uri: uri
    passThrough: true
    acceptEncoding: false
    localStatePassThrough: true
    onResponse: (err, response, request, reply, settings, ttl)->
      log.debug 'proxy response', {err: err, statusCode: response.statusCode, contentType: response.headers['content-type']},
      if err
        reply err
      if not response?
        log.error 'no proxy response', {uri: request.params.uri}
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
