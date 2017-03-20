log = require '../log'

{proxy, proxyPayload} = require '../proxy'

routes = []
routes.push
  method: 'GET'
  path: '/literal:{string}'
  handler: (request, reply) ->
    reply request.params.string

module.exports = routes
