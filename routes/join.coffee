log = require '../log'
uris = require '../uris'
rp = require 'request-promise'

routes = []
routes.push
  method: 'GET'
  path: '/join/{arg*}'
  handler: (request, reply) ->
    arg = request.params.arg

    urls = if arg.endsWith '/'
      arg = '/search:href/' + arg
      uri = uris.expand arg, request.info.host
      rp.get uri: uri
      .then (body)->
        log.debug 'should extract url from ' + body
        urls = body
        urls
    else
      urls = request.params.args.split ','
      new Promise.resolved urls

    urls.then (urls)->
      log.debug 'urls:', urls
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
