log = require '../log'

decorate = (text)->
  "# ${Date.now()} \n" + text

routes = []
routes.push
  method: 'POST'
  path: '/files/{uri*}'
  handler: (request, reply) ->
    path = root.find request.params.uri
    # accept only text payload
    text = request.payload
    # decorate text with date
    text = decorate text
    fs.appendFile(path, text, (err)->
      if err
        reply(err).code(500)
      else
        reply(text).code(201)
module.exports = routes
