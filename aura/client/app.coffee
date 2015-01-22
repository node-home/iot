angular.module 'aura'

.controller 'AuraCtrl', ($scope, socket) ->
  $scope.lights =
    left: '#000'
    right: '#000'

  $scope.objects =
    one: '#f00'
    two: '#00f'

  $scope.$on 'aura:object', (event, {uid, distance}) ->
    console.log 'aura:object', {uid, distance}
    socket.emit 'aura:object', {uid, distance}

  socket.on 'aura:light', ({uid, color}) ->
    $scope.lights[uid] = color


.directive 'auraLight', ->
  restrict: 'E'
  scope:
    uid: '='
    color: '='
  template: """
    <div class="aura-light" style="background-color: {{color}}">{{uid}}</div>
  """

.directive 'auraObject', ->
  restrict: 'E'
  scope:
    uid: '='
    color: '='
  template: """
  <div class="aura-object-bar" style="background-color: {{color}}">
    <div class="aura-object-indicator">{{uid}}</div>
  </div>
  """
  link: (scope, elem) ->
    elem.on 'click', (event) ->
      scope.$emit 'aura:object',
        uid: scope.uid
        distance: event.pageX
