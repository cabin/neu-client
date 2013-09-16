angular.module('neu.team', [])

  .controller 'TeamCtrl', ($scope) ->
    animateDirection = null
    $scope.index = 0
    $scope.$watch 'memberCount', (newValue, oldValue) ->
      sections = [0...newValue]
    # XXX mobile
    $scope.$watch 'viewport.width', (value) ->
      $scope.showMultiple = value >= 768

    $scope.next = ->
      animateDirection = 'left'
      sections.push(sections.shift())
      $scope.index = sections[0]

    $scope.prev = ->
      animateDirection = 'right'
      sections.unshift(sections.pop())
      $scope.index = sections[0]

    $scope.animate = -> "team-#{animateDirection}"
