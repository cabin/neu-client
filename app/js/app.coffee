deps = [
  'ngMobile'
  'neu.controllers'
  'neu.directives'
  'neu.services'
]

module = angular.module('neu', deps)

# Set up Google Analytics.
module.run ['$window', ($window) ->
  $window._gaq = $window._gaq || []
  $window._gaq.push(['_setAccount', 'UA-XXXXX-Y'])  # TODO disable in dev
  $window._gaq.push(['_trackPageview'])

  (->
    d = $window.document
    ga = d.createElement('script')
    ga.type = 'text/javascript'
    ga.async = true
    ga.src = "#{if d.location.protocol is 'https:' then 'https://ssl' else 'http://www'}.google-analytics.com/ga.js"
    s = d.getElementsByTagName('script')[0]
    s.parentNode.insertBefore(ga, s)
  )()
]

# TODO: Investigate whether there's a better solution here; hacking away at the
# root scope seems like too much. And maybe use Modernizr.mq?
module.run ['$window', '$rootScope', ($window, $rootScope) ->
  w = -> $window.innerWidth or $window.document.documentElement.clientWidth
  $rootScope.windowWidth = w()
  angular.element($window).bind 'resize', ->
    $rootScope.$apply(-> $rootScope.windowWidth = w())
]
