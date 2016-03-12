proxy = require './proxy'

sorters =
  recent: (payload, response)->
    content = JSON.parse payload.toString()
    return content.sort (a,b)-> (a.date_added < b.date_added)

wreck = require 'wreck'

routes = []
routes.push
  method: 'GET'
  path: '/sort/{name}/{uri*}'
  handler: (request, reply) ->
    sorter = sorters[request.params.name]
    if not sorter
      reply 404, "cannot find sorter #{request.params.name}"
    proxy request, reply, (err, response, request, reply)->
      if err
        reply err
      wreck.read response, null, (err, payload)->
        if err
          reply err

        console.log 'here', payload.toString()
        reply sorter(payload)


# routes.push
#   method: 'GET'
#   path: '/selectors/{name}/{uri*}'
#   #handler: ...

module.exports = routes
