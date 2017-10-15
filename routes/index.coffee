log = require '../log'

routes = []

routes.push
  method: 'GET',
  path: '/'
  config:
    handler: (request, reply)->
      reply.redirect '/html/text/files/index'

Path = require 'path'

routes.push
  method: 'GET',
  path: '/files/{param*}',
  config:
    handler:
      directory:
        path: Path.join process.cwd(), 'files'
        listing: true

routes.push
  method: 'GET'
  path: '/chart/{uri*}'
  config:
    handler: (request, reply) ->
      proxyPayload request, reply, (err, response, payload)->
        reply.view 'chart',
          uri: request.params.uri
          content: payload.toString()

load = (name)->
  log.debug 'add route', name
  routes.push (require './' + name)...

load 'graph'
load 'slice'
load 'join'
load 'tail'
load 'html'
load 'search'
load 'templates'
load 'literal'
load 'slideshow'
load 'filters'
load 'maps'
load 'transform'
load 'sort'

routes.push
  method: 'GET'
  path: '/routes'
  config:
    handler: (request, reply) ->
      reply routes

routes.push
  method: 'GET'
  path: '/routes/paths'
  config:
    handler: (request, reply) ->
      reply routes.map((route)->route.path).sort()

# {proxy} = require '../proxy'
# routes.push
#   method: 'GET'
#   path: '/{uri*}'
#   config:
#     handler: (request, reply) ->
#       proxy request, reply, (err, response)->
#         if err
#           log.error err
#           return reply err
#         reply response



module.exports = routes
