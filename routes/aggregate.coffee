routes = []

aggregate = (o)->
  if o?.name?  and o?.href?
    o.a = '<a href="#{o.href}">#{o.name}</a>'
    delete o.name
    delete o.href
  o

routes.push
  method: 'GET'
  path: '/aggregate/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = request.params.type
      reply(aggregate(payload)).type(type)

module.exports = routes
