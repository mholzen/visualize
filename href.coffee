# adding HREFs to an object

ar =
  android_result_id: 1
  android_carrier_id: 2
  down: 1
  up: 2

expect(findId(ar)).equal 'android_result_id'

findId = (obj)->
  Object.keys obj

addHref = (obj)->
  if typeof obj != 'object'
    throw new Error()





# if object and all the values have the same keys, it is a collection

# how to express properties of collection
