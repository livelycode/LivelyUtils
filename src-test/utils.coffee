
assert = require 'assert'
utils = require '../lib/utils'
async = require 'async'

test1 =
  a: 2
  b: 3

test1Fun = () -> test1
test1CallbackFun = (cb) -> cb null, test1

test2 =
  a: 4
  b: 9

data1 =
  a: 4
  b:
    c: 4
    d: [5,6]
  c: 7

data2 =
  a: 5
  b:
    c: 5
    d: [6,7]
  c: 8

array1 = [1, 2, 3]
array2 = [1, 3, 5]

describe 'utils', () ->
  describe 'mapObject', () ->
    it 'should async map an object', (done) ->
      utils.mapObject test1, ((key, value, cb) -> cb null, value*value), (err, res) ->
        assert.equal res.a, test2.a
        done()
  describe 'sync.mapObject', () ->
    res = utils.sync.mapObject test1, (key, value) -> value*value
    assert.equal res.a, test2.a
  describe 'mapData', () ->
    it 'should async map any data', (done) ->
      mapFun = (path, value, cb) -> if typeof value is 'number' then cb null, value+1 else cb()
      utils.mapData data1, mapFun, (err, res) ->
        assert.ok res.a is data2.a and res.b.c is data2.b.c and
          res.b.d[0] is data2.b.d[0] and res.c is data2.c
        done()
  describe 'mapArray', () ->
    it 'should async map an array', (done) ->
      utils.mapArray array1, ((value, index, cb) -> cb null, value+index), (err, res) ->
        assert.equal each, array2[index] for each, index in res
        done()
  describe 'ensure', () ->
    it 'tests all three variants', (done) ->
      async.map [test1, test1Fun, test1CallbackFun], utils.ensure, (err, res) ->
        assert.equal each, test1 for each in res
        done()
    it 'tests multiple params', (done) ->
      utils.ensure test1, test1Fun, test1CallbackFun, (err, res...) ->
        assert.equal each, test1 for each in res
        done()
  describe 'merge', () ->
    it 'merges objects', () ->
      merged = utils.merge test1, data2
      assert.equal merged.a, test1.a
      assert.equal merged.c, data2.c