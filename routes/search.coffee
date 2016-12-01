log = require '../log'

{proxy, proxyPayload} = require '../proxy'
cheerio = require 'cheerio'

routes = []

routes.push
  method: 'GET'
  path: '/search:href/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = response?.headers['content-type']
      if type.startsWith('text/html')
        $ = cheerio.load payload
        results = $('a').map( ()->$(this).attr('href')).get()
        results = results.filter (url)->
          url.startsWith('.') or url.startsWith('/'+request.params.uri)
        reply(JSON.stringify(results)).type('application/json')
      else
        reply("cannot search in #{type}").code(400)

module.exports = routes
