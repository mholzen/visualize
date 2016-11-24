# turn a URL with a collection into a websocket

routes = []
routes.push
  method: 'GET'
  path: '/ws/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      toSlice request.params.slice, response, (g)->
        if g instanceof Readable
          reply(g).type(response.headers['content-type'])   # TODO: could be in proxy?
        else
          reply(g).code(404) # error

module.exports = routes
