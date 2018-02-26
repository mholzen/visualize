uris = require './uris'
wreck = require 'wreck'
log = require './log'

error = (response, request)->
  if response.statusCode > 400
    # how to augment response rather than replace
    response =
      statusCode: response.statusCode
      error: response.error
      url: request.params.uri

    log.error 'proxy error', {response}
    return response


# TODO: does not support redirects

proxy = (request, reply, callback)->
  uri = uris.addScheme request
  reply.proxy
    uri: uri
    passThrough: true
    acceptEncoding: false
    localStatePassThrough: true
    onResponse: (err, response, request, reply, settings, ttl)->
      log.debug {err, uri, stausCode: response.statusCode, 'content-type': response.headers['content-type']}, 'received'
      if (errorResponse = error(response, request))
        return reply(errorResponse)

      callback err, response, request, reply, settings, ttl

proxyPayload = (request, reply, callback)->
  uri = uris.addScheme request
  log.debug {uri}, 'proxy request'
  reply.proxy
    uri: uri
    passThrough: true
    acceptEncoding: false
    localStatePassThrough: true
    onResponse: (err, response, request, reply, settings, ttl)->
      log.debug {err: err, statusCode: response.statusCode, contentType: response.headers['content-type']}, 'proxy response'
      if err
        reply err
      if not response?
        log.error 'no proxy response', {uri: request.params.uri}
      if [301, 302].includes response.statusCode
        return reply response
      if (errorResponse = error(response, request))
        return reply(errorResponse)
      wreck.read response, null, (err, payload)->
        if err
          reply err
        callback err, response, payload, request, reply, settings, ttl


module.exports =
  proxy: proxy
  proxyPayload: proxyPayload
