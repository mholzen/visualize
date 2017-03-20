log = require '../log'

{proxy, proxyPayload} = require '../proxy'
cheerio = require 'cheerio'
url = require 'url'

routes = []

searches =
  href: ($)->
    $('a').map ()->$(this).prop('href')
    .get()

  images: ($)->
    $('img').map( ()->
      $(this).attr('src')
    ).get()


routes.push
  method: 'GET'
  path: '/search:{query}/{uri*}'
  handler: (request, reply) ->
    log.debug request.url, url.format(request.url)
    proxyPayload request, reply, (err, response, payload)->
      type = response?.headers['content-type'] ? 'text/html'
      if type?.startsWith('text/html')
        $ = cheerio.load payload.toString()
        log.debug payload: payload.toString()
        results = searches[request.params.query]($)
        # results = results.filter (url)->
        #   url.startsWith('.') or url.startsWith('/'+request.params.uri)
        reply(JSON.stringify(results)).type('application/json')
      else
        reply("cannot search in #{type}").code(400)

module.exports = routes
