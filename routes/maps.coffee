{proxy, proxyPayload} = require '../proxy'
log = require '../proxy'

routes = []

{Parser} = require 'htmlparser2'
{Writable} = require 'stream'
wreck = require 'wreck'

routes.push
  method: 'GET'
  path: '/prefix:{prefix}/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, res, request, reply, settings, ttl)->
      response = ''
      parser = new Parser({
        onopentag: (name, attribs) ->
          response += '<'+name+' '
          if name == 'a'
            attribs.href = '/' + request.params.prefix + attribs.href
          response += "#{key}=\"#{value}\" "for key, value of attribs
          response += '>'
        ontext: (text)->
          response += text
        onclosetag: (name)->
          response += '</'+name+'>'
      }, decodeEntities: true)

      wreck.read res, null, (err, payload)->
        parser.write payload.toString()
        parser.end()
        reply null, response

# maps by name
cson = require 'cson'
boom = require 'boom'



routes.push
  method: 'GET'
  path: '/balance/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = response.headers['content-type']
      if not type.startsWith 'application/json'
        return reply('need json').code(400)
      payload = JSON.parse payload
      payload.forEach (item)->item['_Date']=Date.parse(item['Date'])
      # payload = payload.sort (a,b)->Date.compare(Date.parse(a['Date']),Date.parse(b['Date']))
      payload = payload.sort (a,b)->Date.compare(a['_Date'],b['_Date'])
      AmountTotal = 0.0
      payload.forEach (item)->
        Amount = parseFloat(item['Amount'])
        AmountTotal += if item['Transaction Type'] == 'credit' then Amount else -Amount
        item['AmountTotal'] = AmountTotal
      reply(payload)


module.exports = routes
