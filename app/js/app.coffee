deps = [
  'ngMobile'
  'neu.controllers'
  'neu.directives'
  'neu.services'
]

module = angular.module('neu', deps)

# Hide the navigation bar on mobile.
module.run ['$window', 'getScrollTop', ($window, getScrollTop) ->
  # Trivial implementation: not worried about Android support, and we're not
  # using location hashes so there's no need to avoid breaking them. See
  # <https://gist.github.com/scottjehl/1183357> for a proper implementation.
  return if getScrollTop() > 10
  $window.scrollTo(0, 0)
]

# Set up Google Analytics.
module.run ['$window', ($window) ->
  trackingID = 'UA-42012866-1'
  domain = 'neu.me'
  if $window.location.host in ['localhost', 'neu.dev', 'staging.neu.me']
    trackingID = 'UA-42012866-2'
    domain = "staging.#{domain}"

  # Embedded JS copypasta from Google.
  `(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');`

  ga('create', trackingID, domain)
  ga('send', 'pageview')
]

# Keep track of the viewport's width through resize events.
# TODO: Investigate whether there's a better solution here; hacking away at the
# root scope seems like too much. And maybe use Modernizr.mq?
module.run ['$window', '$rootScope', ($window, $rootScope) ->
  w = -> $window.innerWidth or $window.document.documentElement.clientWidth
  $rootScope.windowWidth = w()
  angular.element($window).bind 'resize', ->
    $rootScope.$apply(-> $rootScope.windowWidth = w())
]
