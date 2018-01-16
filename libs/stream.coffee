csvparse = require 'csv-parse'
split = require 'split2'
CSON = require 'cson-parser'
highland = require 'highland'
log = require '../log'
{parse} = require 'transform'

toObjectStream = (response)->
  type = response.headers['content-type']
  if not type?
    log.warn headers: response.headers, path: response.path, 'no content-type in response'
    type = 'text/csv'
  log.debug {
    type
    payload: response.payload
    }, 'toObjectStream'
  switch
    when type.startsWith 'application/json'
      # WARNING: assumes it is JSON lines.  what if single JSON object?
      # response.pipe(split(CSON.parse))
      response.payload.pipe parse

    when type.startsWith('text/csv')
      parser = csvparse()#{columns: true})
      parser.on 'error', (err)->
        log.error err, 'parser error'
      if response.payload?
        log.debug payload: response.payload.toString(), 'payload to stream'
        parser.end(response.payload.toString())
        parser
      else
        response.pipe parser

    when type.startsWith('text/') or type.startsWith('application/octet-stream') or type.startsWith('application/x-www-form-urlencoded')
      payload = if response.payload? then response.payload else response
      parse(payload)

    else
      throw new Error "cannot create stream from #{type}"

toHighland = (respone)->
  highland(toObjectStream(respone))

module.exports = {
  toObjectStream
  toHighland
}
