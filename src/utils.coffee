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

class Data
  constructor: (requiredData, dataFun) ->
    [@requiredData, @dataFun] = if dataFun then [requiredData, dataFun]
    else [[], requiredData]
    @requiredData = for data in @requiredData
      if data.constructor is Data then data else new Data data
  data: (cb) ->
    if @dataCached then return cb null, @dataCached
    dataFun = @dataFun
    that = this
    finished = (err, result) ->
      that.dataCached = result
      cb err, result
    if typeof dataFun isnt 'function' then finished null, dataFun
    else if dataFun.length is 0 then finished null, dataFun()
    else if @requiredData.length is 0 and dataFun.length is 1 then dataFun finished
    else
      mapFun = (each, cb) -> each.data cb
      async.map @requiredData, mapFun, (err, dataRes) ->
        if dataFun.length is 2 then that.dataFun dataRes, finished
        else finished null, dataFun dataRes

module.exports =
  mapObject: mapObject
  mapData: (object, mapFun, cb) -> mapData [], object, mapFun, cb
  mapArray: mapArray
  data: (requiredData, dataOrFun) -> new Data requiredData, dataOrFun
  Data: Data