angular.module('neu.scrolling', [])

  # Cross-browser `scrollY`.
  .factory 'getScrollTop', ($window) ->
    if $window.pageYOffset?
      -> $window.pageYOffset
    else
      -> $window.document.documentElement.scrollTop  # IE8

  .factory 'fixedHeaderHeight', ->
    fixedHeaderHeight = 0
    subscribers = []
    get: -> fixedHeaderHeight
    set: (val) -> fixedHeaderHeight = val
    subscribe: (callback) ->
      subscribers.push(callback)
    reset: ->
      callback() for callback in subscribers

  # Scroll smoothly to the given y-coordinate.
  .factory 'scrollTo', ($window, fixedHeaderHeight) ->
    (to) ->
      to -= fixedHeaderHeight.get()
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
    (elm) -> scrollTo(elementY(elm))

  # Provide a smooth scrolling animation to the given in-page href.
  .directive 'neuSmoothScroll', (scrollToElement, $window) ->
    restrict: 'A'
    link: (scope, elm, attrs) ->
      return unless attrs.href.indexOf('#') is 0
      id = attrs.href.slice(1)
      elm.bind 'click', (event) ->
        event.preventDefault()
        scrollToElement($window.document.getElementById(id))

  # Set `.site-header` element to fixed position, adjusting body padding to
  # account for its height. If there is no `.subnav` child element, add a class
  # to provide border styling.
  # TODO: consider moving the logic in enableSlideshow to here
  # XXX adjust fixedHeaderHeight (and page-top padding) on resize
  .directive 'siteHeader', (fixedHeaderHeight) ->
    restrict: 'C'
    priority: 2
    link: (scope, elm, attrs) ->
      do adjust = ->
        elm.css(position: 'fixed')
        h = elm[0].clientHeight
        fixedHeaderHeight.set(h)
        angular.element(document.querySelector('.page-top')).css
          paddingTop: "#{h}px"
      fixedHeaderHeight.subscribe(adjust)
