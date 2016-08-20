log = require '../log'
uris = require '../uris'
rp = require 'request-promise'

routes = []
routes.push
  method: 'GET'
  path: '/join/{urls*}'
  handler: (request, reply) ->
    urls = request.params.urls.split ','
    log.debug 'split urls', urls
    requests = urls.map (url)->
      url = uris.expand url, request.info.host
      rp.get
        uri: url
        resolveWithFullResponse: true

    Promise.all requests
    .then (responses)->
      content =
        responses.map (response)->response.body
        .join('')
      lastResponse = responses[-1..][0]
      reply(content)
      .type(lastResponse.headers['content-type'])
    .catch (err)->
      log.debug err
      reply
        uri: err.options.uri
      .code(err.statusCode)

module.exports = routes
