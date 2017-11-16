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
      arg = 'search:href/' + arg
      uri = uris.expand arg, request.info.host
      rp.get(uri: uri)
      .then (body)->
        log.debug 'should extract url from ' + body
        urls = JSON.parse body
        urls
    else
      urls = request.params.args.split ','
      new Promise.resolved urls

    urls.then (urls)->
      log.debug 'urls:', urls

      # do not recurse, so filter urls that are collections
      # urls = urls.filter (url)->not url.endsWith '/'

      urls = urls.map (url)->
        (if url.endsWith '/' then '/search:href' else '') + url

      log.debug 'after recurse', urls: urls

      requests = urls.map (url)->
        url = uris.expand url, request.info.host
        log.debug 'get '+url
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
