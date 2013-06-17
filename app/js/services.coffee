module = angular.module('neu.services', [])

# Whether the current display devices has "retina" resolution.
module.factory 'isRetina', ['$window', ($window) ->
  ->
    if $window.devicePixelRatio? && $window.devicePixelRatio >= 1.5
      return true
    mq = "(-webkit-min-device-pixel-ratio: 1.5),
          (min--moz-device-pixel-ratio: 1.5),
          (-o-min-device-pixel-ratio: 3/2),
          (min-resolution: 1.5dppx)"
    $window.matchMedia?(mq).matches or false
]


module.factory 'preload', ['$window', ($window) ->
  (src, success, error) ->
    img = new $window.Image()
    img.onload = success if success?
    img.onerror = error if error?
    img.src = src
]
