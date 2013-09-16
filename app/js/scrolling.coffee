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
    (to, offset = 160) ->
      to -= offset
      TweenLite.to($window, .4, scrollTo: {y: to}, ease: Power2.easeInOut)

  .factory 'elementY', (getScrollTop) ->
    (elm) ->
      return 0 unless elm
      # Grab the first match if this is a wrapped element.
      elm = elm[0] if (elm.bind and elm.find)
      rect = elm.getBoundingClientRect()
      # TODO: jQuery also accounts for docElem.clientTop. Why?
      # https://github.com/jquery/jquery/blob/80538b04fd4ce8bd531d3d1fb60236a315c82d80/src/offset.js#L105
      rect.top + getScrollTop()

  # Scroll smoothly to the given element.
  .factory 'scrollToElement', (scrollTo, elementY) ->
    (elm) ->
      rect = elm.getBoundingClientRect()
      scrollTo(elementY(elm))

  # Provide a smooth scrolling animation to the given in-page href.
  .directive 'neuSmoothScroll', (scrollToElement, $window) ->
    restrict: 'A'
    link: (scope, elm, attrs) ->
      return unless attrs.href.indexOf('#') is 0
      id = attrs.href.slice(1)
      elm.bind 'click', (event) ->
        event.preventDefault()
        scrollToElement($window.document.getElementById(id))
