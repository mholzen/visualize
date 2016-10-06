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

routes.push (require './graph')...

routes.push (require './slice')...

routes.push (require './join')...

routes.push (require './tail')...

routes.push require './slideshow'
routes.push require './filters'

routes.push require './maps'

routes.push require './transform'

routes.push require './sort'

routes.push (require './html')...

routes.push (require './templates') ...

module.exports = routes
