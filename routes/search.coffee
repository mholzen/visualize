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
        result = $('a').map ()->$(this).attr('href')
        reply(JSON.stringify(result.get())).type('application/json')
      else
        reply("cannot search in #{type}").code(400)

module.exports = routes
