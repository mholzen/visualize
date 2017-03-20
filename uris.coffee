expand = (uri, host)->
  if (uri.startsWith 'http://') or (uri.startsWith 'https://')
    return uri
  if uri.match /^(\w+\.){1,}\w+$/
    host = uri
    uri = ''
  if uri.length > 0 and not uri.startsWith '/'
    uri = '/' + uri
  return 'http://' + host + uri

addScheme = (request)->
  uri = request?.params?.uri
  return if not uri?
  expand uri, request.info.host

module.exports =
  expand: expand
  addScheme: addScheme
