module = angular.module('neu.controllers', [])

module.controller('SplashCtrl', ['$scope', '$timeout', 'preload', ($scope, $timeout, preload) ->
  delay = 4000
  data = [
    {name: 'university', img: 'http://placehold.it/200x250&text=university',
    text: 'Hands-on, project based, collaborative, & fun.'}
    {name: 'creators', img: 'http://placehold.it/200x250&text=creator',
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
  $scope.sectionCount = 6  # NOTE: this must reflect the total team sections.
  sections = [0...$scope.sectionCount]
  animateDirection = null

  $scope.$watch 'windowWidth', ->
    $scope.showMultiple = $scope.windowWidth >= 768

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
  $scope.state =
    invalid: false     # avoid showing errors until initial submission
    submitting: false  # avoid multiple submissions
    submitted: false   # hide the form after successful submission
    submissionFailed: false
  $scope.data = {}

  postData = ->
    promise = $http.post('/api/prospects', $scope.data)
    promise.success (data, status, headers, config) ->
      $scope.state.submitted = true
      $window.ga('send', 'event', 'Initial sign-up form', 'Submitted')
    promise.error (data, status, headers, config) ->
      $scope.state.submitting = false
      $scope.state.submissionFailed = true
      $window.ga('send', 'event', 'Initial sign-up form', 'Failed submission')

  $scope.submit = ->
    return if $scope.state.submitting
    if $scope.form.$valid
      $scope.state.submitting = true
      postData()
    else
      $scope.state.invalid = true
])


module.controller('ShareCtrl', ['$scope', '$window', ($scope, $window) ->
  popupSizes =
    facebook: [580, 325]
    twitter: [550, 420]
    google: [600, 600]
    linkedin: [520, 570]

  $scope.share = ($event, type) ->
    $event.preventDefault()
    url = angular.element($event.target).attr('href')
    [width, height] = popupSizes[type]
    screen = $window.screen
    left = (screen.availWidth or screen.width) / 2 - width / 2
    top = (screen.availHeight or screen.height) / 2 - height / 2
    features = "width=#{width},height=#{height},left=#{left},top=#{top}"
    # NOTE: We don't have a reliable way to measure *completed* share
    # interactions; this just measures the number of times someone opened a
    # share window, whether or not they went on to successfully share.
    $window.ga('send', 'social', type, 'share', 'http://neu.me/')
    $window.open(url, '_blank', features)
])
