wreck = require 'wreck'
{expand} = require '../uris'
log = require '../log'
{proxy, proxyPayload} = require '../proxy'
{toObjectStream} = require '../libs/stream'

routes = []

routes.push
  method: 'GET'
  path: '/templates/{template}'
  handler: (request, reply) ->
    reply.view request.params.template

routes.push
  method: 'POST'
  path: '/templates/{template}'
  config:
    payload:
      output: 'stream'
    handler: (request, reply) ->
      stream = toObjectStream request
      stream.on 'error', (err)->
        log.debug count: count, 'responding'
        reply('parser error', err).code(500)

      stream.toArray (payload)->
        reply.view request.params.template, {payload: JSON.stringify(payload)}


noPassThrough = false
routes.push
  method: 'GET'
  path: '/templates/{template}/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      if err
        log.error err
        reply err
      if noPassThrough or response.headers['content-type']?.startsWith 'text/'
        reply.view request.params.template,
          uri: '/' + request.params.uri
          payload: payload
          content: payload?.toString()
          get: (url)->'GET ' + url
      else
        # pass-through, which really calls for /{uri*}/templates/{template}
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
