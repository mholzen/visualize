expand = (uri, host)->
  if uri.match /^\w+\.\w+$/
    host = uri
    uri = ''
  if uri.startsWith 'http://'
    return uri
  if not uri.startsWith '/'
    uri = '/' + uri
  return 'http://' + host + uri

addScheme = (request)->
  uri = request?.params?.uri
  return if not uri?
  expand uri, request.info.host

module.exports =
  expand: expand
  addScheme: addScheme
