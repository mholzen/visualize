wreck = require 'wreck'

templates =
  method: 'GET'
  path: '/templates/{template}/{uri*}'
  handler: (request, reply) ->
    uri = 'http://' + request.info.host + '/' + request.params.uri
    reply.proxy
      uri: uri
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, {json: true}, (err, payload)->
          console.log payload
          reply.view request.params.template,
            uri: uri
            payload: payload

proxy = require './proxy'
{dirname} = require 'path'

jade =
  method: 'GET'
  path: '/jade/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->

      reply.proxy
        uri: (dirname request.params.uri) + '.jade'
        onResponse: (err, response, request, reply, settings, ttl)->

      #   wreck.read res, {json: true}, (err, payload)->
      #     reply.view request.params.template,
      #       uri: uri
      #       payload: payload

module.exports = [templates, jade]
