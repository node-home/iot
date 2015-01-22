flow = require 'home.flow'
spot = require 'home.spot'

models = require '../models'
utils  = require '../utils'

mixArua = (components, {radiusMin, radiusMax}) ->
  totalWeight = 0

  for c in components
    c.weight = switch
      when c.distance <= radiusMin then 1
      when c.distance >= radiusMax then 0
      else 1 - (c.distance - radiusMin) / (radiusMax - radiusMin)

    totalWeight += c.weight

  utils.mix (color: c.color, weight: c.weight / totalWeight for c in components)

createAura = (light, options={}) ->
  aura =
    light: light
    components: {}

  params = obj1: light.uuid

  aura.listener = spot.feeds.distance params, ({distance, obj2}) ->
    aura.components[obj2]?.distance = distance
    mixAura light.components, options


run = (options) ->
  options.radiusMin ?= 10
  options.radiusMax ?= 50

  auras = {}

  models.Light.list()

  .then (lights) ->
    for light in lights
      aura[light.uuid] = createAura light, options
