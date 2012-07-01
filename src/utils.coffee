async = require 'async'

descend = (currentPath, object, mapFun, cb) ->
  switch object.constructor
    when Array
      eachMap = (each, index, cb) ->
        mapData (currentPath.concat [index]), each, mapFun, cb
      mapArray object, eachMap, cb
    when Object
      eachMap = (key, value, cb) ->
        mapData (currentPath.concat [key]), value, mapFun, cb
      mapObject object, eachMap, cb
    else
      cb null, object

# should add a state parameter to mapFun
mapData = (currentPath, object, mapFun, cb) ->
  mapFun currentPath, object, (err, result) ->
    if result then cb err, result
    else descend currentPath, object, mapFun, (err, res) -> cb err, res

mapArray = (array, mapFun, cb) ->
  newArray = []
  mapWrapper = (index, cb) ->
    mapFun array[index], index, (err, res) ->
      newArray[index] = res
      cb()
  async.forEach [0..array.length-1], mapWrapper, () -> cb null, newArray

mapObject = (object, mapFun, cb) ->
  newObj = {}
  map = (key, value) -> (cb) ->
    mapFun key, value, (err, res) ->
      newObj[key] = res
      cb()
  tasks = (map key, value for key, value of object)
  async.parallel tasks, () -> cb null, newObj

sync = {}
sync.mapObject = (object, mapFun) ->
  newObj = {}
  (newObj[key] = mapFun key, value) for key, value of object
  newObj
# passes the evaluated result of value to callback (no matter if sync or async)
ensure = (values..., cb) ->
  map = (value, cb) ->
    if typeof value is 'function'
      switch value.length
        when 0 then cb null, value()
        when 1 then value cb
    else cb null, value
  async.map values, map, (err, res) -> cb null, res...

merge = (objects...) ->
  newObj = {}
  for each in objects
    for key, value of each
      if not newObj[key] then newObj[key] = value
  newObj

module.exports =
  mapObject: mapObject
  mapData: (object, mapFun, cb) -> mapData [], object, mapFun, cb
  mapArray: mapArray
  ensure: ensure
  sync: sync
  merge: merge