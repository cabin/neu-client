module = angular.module('neu.controllers', [])

module.controller('MainCtrl', ['$scope', ($scope) ->
  $scope.msg = 'Hello from NEU!'
])
