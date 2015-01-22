# Add a light bulb and it's position
# Add a aura object and it's color
# Listen for distance events
# Set combined light value per bulb

auraMix = (components, {radiusMin, radiusMax}) ->
  totalWeight = 0

  for c in components
    c.weight = switch
      when c.distance <= radiusMin then 1
      when c.distance >= radiusMax then 0
      else 1 - (c.distance - radiusMin) / (radiusMax - radiusMin)

    totalWeight += c.weight

  utils.mix (color: c.color, weight: c.weight / totalWeight for c in components)

