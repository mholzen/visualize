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

log.debug 'graph'
routes.push (require './graph')...
log.debug 'slice'
routes.push (require './slice')...
log.debug 'join'
routes.push (require './join')...
log.debug 'tail'
routes.push (require './tail')...
log.debug 'html'
routes.push (require './html')...
log.debug 'search'
routes.push (require './search')...
log.debug 'templates'
routes.push (require './templates') ...
log.debug 'literal'
routes.push (require './literal') ...
log.debug 'slideshow'
routes.push require './slideshow'
log.debug 'filters'
routes.push require './filters'
log.debug 'maps'
routes.push require './maps'
log.debug 'transform'
routes.push require './transform'
log.debug 'sort'
routes.push require './sort'

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
