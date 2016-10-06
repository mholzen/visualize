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
            console.log err
          console.log request.params.template
          r = reply.view request.params.template,
            uri: uri
            payload: payload
            content: payload.toString()
            get: (url)->'GET ' + url

{proxy, proxyPayload} = require '../proxy'
{dirname} = require 'path'
rp = require 'request-promise'
pug = require 'pug'

routes.push
  method: 'GET'
  path: '/pug/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      template = pug.compile payload
      urls = []
      template
        get: (url)->urls.push expand(url, request.info.host)
      log.debug urls, 'here'

      Promise.all urls.map (url)->rp url
      .then (contents)->
        reply template
          get: (url)->contents.pop()
      .catch (error)->
        reply(error).code(500)

module.exports = routes
