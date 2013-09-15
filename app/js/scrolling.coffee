angular.module('neu.scrolling', [])

  # Cross-browser `scrollY`.
  .factory 'getScrollTop', ($window) ->
    if $window.pageYOffset?
      -> $window.pageYOffset
    else
      -> $window.document.documentElement.scrollTop  # IE8

  # Scroll smoothly to the given y-coordinate.
  .factory 'scrollTo', ($window, getScrollTop) ->
    # XXX Account for the fixed header, so we don't put the scrolled-to element
    # behind it. Perhaps just parse out the top padding on `.page-top`? For
    # now, magic numbers!
    offset = 160
    (to) ->
      to -= offset
      TweenLite.to($window, .4, scrollTo: {y: to}, ease: Power2.easeInOut)

  # Scroll smoothly to the given element.
  .factory 'scrollToElement', (scrollTo, getScrollTop) ->
    (elm) ->
      rect = elm.getBoundingClientRect()
      # TODO: jQuery also accounts for docElem.clientTop. Why?
      # https://github.com/jquery/jquery/blob/80538b04fd4ce8bd531d3d1fb60236a315c82d80/src/offset.js#L105
      scrollTo(rect.top + getScrollTop())

  # Provide a smooth scrolling animation to the given in-page href.
  .directive 'neuSmoothScroll', (scrollToElement, $window) ->
    restrict: 'A'
    link: (scope, elm, attrs) ->
      return unless attrs.href.indexOf('#') is 0
      id = attrs.href.slice(1)
      elm.bind 'click', (event) ->
        event.preventDefault()
        scrollToElement($window.document.getElementById(id))
