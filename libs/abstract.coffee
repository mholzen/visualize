module.exports = (obj)->
  if obj.url? and obj.name?
    obj.anchor='<a href="#{obj.url}">#{obj.name}</a>'
    delete obj.url
    delete obj.name

  obj
