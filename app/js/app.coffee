deps = [
  'ngMobile'
  'neu.controllers'
  'neu.directives'
  'neu.services'
]

module = angular.module('neu', deps)

# TODO: Investigate whether there's a better solution here; hacking away at the
# root scope seems like too much. And maybe use Modernizr.mq?
module.run ['$window', '$rootScope', ($window, $rootScope) ->
  w = -> $window.innerWidth or $window.document.documentElement.clientWidth
  $rootScope.windowWidth = w()
  angular.element($window).bind 'resize', ->
    $rootScope.$apply(-> $rootScope.windowWidth = w())
]
