wreck = require 'wreck'
{expand} = require '../uris'
log = require '../log'
{proxy, proxyPayload} = require '../proxy'

routes = []

routes.push
  method: 'GET'
  path: '/templates/{template}'
  handler: (request, reply) ->
    reply.view request.params.template

routes.push
  method: 'GET'
  path: '/templates/{template}/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      if err
        log.error err
        reply err
      if response.headers['content-type']?.startsWith 'text/'
        reply.view request.params.template,
          uri: request.params.uri
          payload: payload
          content: payload?.toString()
          get: (url)->'GET ' + url
      else
        reply(payload).headers = response.headers


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
