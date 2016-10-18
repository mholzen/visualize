wreck = require 'wreck'
{expand} = require '../uris'
log = require '../log'

routes = []
routes.push
  method: 'GET'
  path: '/templates/{template}/{uri*}'
  handler: (request, reply) ->
    uri = 'http://' + request.info.host + '/' + request.params.uri
    reply.proxy
      uri: uri
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, {json: true}, (err, payload)->
          if err
            log.error err
            return reply err
          reply.view request.params.template,
            uri: uri
            payload: payload
            content: payload?.toString()
            get: (url)->'GET ' + url

{proxy, proxyPayload} = require '../proxy'
{dirname} = require 'path'
rp = require 'request-promise'
pug = require 'pug'

routes.push
  method: 'GET'
  path: '/pug/{template*}'
  handler: (request, reply) ->
    request.params.uri = request.params.template
    proxyPayload request, reply, (err, response, template)->
      template = pug.compile template,
        filename: request.params.uri
      urls = []
      template
        get: (url)->urls.push expand(url, request.info.host)

      Promise.all urls.map (url)->rp url
      .then (contents)->
        reply template
          get: (url)->contents.pop()
      .catch (error)->
        reply(error).code(500)

module.exports = routes
