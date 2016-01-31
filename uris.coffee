module.exports =
  addScheme: (request)->
    uri = request?.params?.uri
    return if not uri?
    if uri.indexOf('http') != 0
       uri = 'http://' + request.info.host + '/' + uri
    return uri
