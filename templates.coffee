wreck = require 'wreck'

module.exports =
  method: 'GET'
  path: '/templates/{template}/{uri*}'
  handler: (request, reply) ->
    uri = 'http://' + request.info.host + '/' + request.params.uri
    reply.proxy
      uri: uri
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, {json: true}, (err, payload)->
          reply.view request.params.template,
            uri: uri
