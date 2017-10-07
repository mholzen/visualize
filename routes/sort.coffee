{proxyPayload} = require '../proxy'

getDate = (o)->
  o.date_added ? o.timestamp

toDateInt = (o)->
  if /^\d+$/.test o
    parseInt o
  else
    Date.parse o

sorters =
  recent: (payload, response)->
    content = JSON.parse payload.toString()
    content = content.sort (a,b)-> (toDateInt(getDate(b)) - toDateInt(getDate(a)))
    return content

routes = []
routes.push
  method: 'GET'
  path: '/sort:{name}/{uri*}'
  handler: (request, reply) ->
    sorter = sorters[request.params.name]
    if not sorter
      reply 404, "cannot find sorter #{request.params.name}"
    proxyPayload request, reply, (err, response, payload)->
      if err
        reply err
      reply sorter(payload)


# routes.push
#   method: 'GET'
#   path: '/selectors/{name}/{uri*}'
#   #handler: ...

module.exports = routes
