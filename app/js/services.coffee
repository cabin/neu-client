module = angular.module('neu.services', [])


module.factory 'getScrollTop', ['$window', ($window) ->
  if $window.scrollY?
    -> $window.scrollY
  else
    -> $window.document.documentElement.scrollTop  # IE8
]
