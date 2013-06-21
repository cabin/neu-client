module = angular.module('neu.controllers', [])

module.controller('SplashCtrl', ['$scope', '$timeout', 'preload', ($scope, $timeout, preload) ->
  delay = 4000
  data = [
    {name: 'university', img: '/img/lorempixel/cats5.jpg',
    text: 'Hands-on, project based, collaborative, & fun.'}
    {name: 'creators', img: '/img/lorempixel/cats6.jpg',
    text: 'Diverse<br>in gender, ethnicity,<br>and creative spirit.'}
  ]
  index = -1

  for item in data
    preload(item.img)

  cycle = ->
    index += 1
    if index >= data.length
      index = 0
    $scope.sel = data[index]
    $timeout(cycle, delay)
    # Avoid the implicit return of `$timeout()`s return value, which is a
    # promise and would otherwise be leaking.
    return
  cycle()
])


module.controller('TeamCtrl', ['$scope', '$window', ($scope, $window) ->
  $scope.sectionCount = 4  # NOTE: this must reflect the total team sections.
  sections = [0...$scope.sectionCount]
  animateDirection = null

  $scope.$watch 'windowWidth', ->
    $scope.showMultiple = $scope.windowWidth > 768

  $scope.index = 0

  $scope.next = ->
    animateDirection = 'left'
    sections.push(sections.shift())
    $scope.index = sections[0]

  $scope.prev = ->
    animateDirection = 'right'
    sections.unshift(sections.pop())
    $scope.index = sections[0]

  $scope.animate = -> "team-#{animateDirection}"
])


module.controller('JoinCtrl', ['$scope', '$http', '$window', ($scope, $http, $window) ->
  $scope.invalid = false  # avoid showing errors until initial submission
  $scope.submitting = false  # avoid multiple submissions

  postData = ->
    promise = $http.post '/api/prospects', JSON.stringify
      name: $scope.name
      email: $scope.email
      zip: $scope.zip
      note: $scope.note
    promise.success(-> console.log 'success', arguments)
    promise.error (data, status, headers, config) ->
      $scope.submitting = false
      console.log 'error', data, headers('foo'), config

  $scope.submit = ->
    return if $scope.submitting
    if $scope.form.$valid
      $scope.submitting = true
      $window._gaq.push(['_trackEvent', 'submit'])  # XXX test
      postData()
    else
      $scope.invalid = true
])
