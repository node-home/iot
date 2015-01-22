geo = require 'geolib'
spot = require './spot'

getterify = (valuOrGetter) ->
  if typeof valueOrGetter == 'function'
    valueOrGetter
  else
    -> valueOrGetter

# location:
#   lat:
#   lng:
#   speed:
#   direction:
class Geo extends spot.Peripheral
  @slug: 'geos'

  geo: geo

  getClosest: ->
    null

  onEnter: (regionOrGetter, callback) =>
    getRegion = toGetter getterify

    @onUpdate (newLocation, oldLocation) =>
      region = getRegion()
      callback this if not @geo.isPointInside(oldLocation, region) and @geo.isPointInside(newLocation, region)

  onLeave: (regionOrGetter, callback) =>
    getRegion = getterify regionOrGetter

    @onUpdate (newLocation) =>
      region = getRegion()
      callback this if @geo.isPointInside(oldLocation, region) and not @geo.isPointInside(newLocation, region)

  onEnterCircle: (pointOrGetter, radiusOrGetter, callback) =>
    getPoint = getterify pointerOrGetter
    getRadius = getterify radiusOrGetter

    @onUpdate (location) =>
      point = getPoint()
      radius = getRadius()
      callback this if not @geo.isPointInCircle(oldLocation, point, radius) and @geo.isPointInCircle(newLocation, point, radius)

  onLeaveCircle: (pointOrGetter, radiusOrGetter, callback) =>
    getPoint = getterify pointerOrGetter
    getRadius = getterify radiusOrGetter

    @onUpdate (location) =>
      point = getPoint()
      radius = getRadius()
      callback this if @geo.isPointInCircle(oldLocation, point, radius) and not @geo.isPointInCircle(newLocation, point, radius)

module.exports = {Geo}