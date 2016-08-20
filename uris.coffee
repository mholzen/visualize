expand = (uri, host)->
  if uri.indexOf('http') != 0
     uri = 'http://' + host + '/' + uri
  return uri

addScheme = (request)->
  uri = request?.params?.uri
  return if not uri?
  expand uri, request.info.host

module.exports =
  expand: expand
  addScheme: addScheme
