routes = []

aggregate = (o)->
  if o?.name?  and o?.href?
    o.a = '<a href="#{o.href}">#{o.name}</a>'
    delete o.name
    delete o.href
  o

routes.push
  method: 'GET'
  path: '/state/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = request.params.type
      if not type.startsWith 'text/html'
        reply('cannot support #{type}').status(404)
      $ = cheerio.load payload
      $('head').append('<script src="/files/state.js"/>')
      reply($)

module.exports = routes
