deps = [
  'ngMobile'
  'cabin.at2x'
  'neu.nav'
  'neu.ie'
  'neu.scrolling'
  'neu.placeholder'
  'neu.rfi'
  'neu.homepage'
]

module = angular.module('neu', deps)

# Set up Google Analytics.
module.run ['$window', ($window) ->
  trackingID = 'UA-42012866-1'
  domain = 'neu.me'
  if $window.location.host isnt domain
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


# From underscore.js.
debounce = (func, wait, immediate) ->
  timeout = result = null
  ->
    context = this
    args = arguments
    later = ->
      timeout = null
      result = func.apply(context, args) unless immediate
    callNow = immediate and not timeout
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
    result = func.apply(context, args) if callNow
    result

# Centralize tracking of viewport size and scroll amount.
# TODO: Investigate whether there's a better solution here; hacking away at the
# root scope seems like too much. And maybe use Modernizr.mq?
module.run ['$window', '$rootScope', 'getScrollTop', ($window, $rootScope, getScrollTop) ->
  $rootScope.viewport = {}
  # Always use documentElement.clientWidth for the width; it accounts for any
  # visible scrollbar. Use window.innerHeight for height if it's available,
  # since we *don't* want to account for the browser chrome in iOS.
  w = -> $window.document.documentElement.clientWidth
  h = -> $window.innerHeight or $window.document.documentElement.clientHeight

  do updateSizes = ->
    $rootScope.$apply ->
      $rootScope.viewport.width = w()
      $rootScope.viewport.height = h()
    updateScroll?()  # in case previous scrollTop is now out of range
  do updateScroll = -> $rootScope.$apply ->
    $rootScope.viewport.scroll = getScrollTop()

  handleOrientationChange = ->
    # Thanks to <http://mrdarcymurphy.tumblr.com/post/5574489334/>.
    ss = $window.document.styleSheets[0]
    try
      ss.addRule('force-reflow', 'position: relative')
    catch e
      # ignored
    updateSizes()

  angular.element($window).bind('resize', debounce(updateSizes, 100))
  angular.element($window).bind('orientationchange', handleOrientationChange)
  angular.element($window).bind('scroll', updateScroll)
]
