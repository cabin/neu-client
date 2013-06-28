module = angular.module('neu.directives', [])

# Return the y-offset relative to the document for the given `element`, which
# can be an angular Element or a DOM node.
yOffset = (element) ->
  return 0 unless element
  # Grab the first match if this is a wrapped element.
  element = element[0] if (element.bind and element.find)
  offset = element.offsetTop
  node = element
  while node.offsetParent and node.offsetParent isnt window.document.body
    node = node.offsetParent
    offset += node.offsetTop
  offset

# For images with an `at2x` attribute, and only on retina displays, attempt to
# load a retina asset (<filename>@2x.<ext>) and swap it out for the existing
# asset on success.
module.directive 'at2x', ['isRetina', 'preload', (isRetina, preload) ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    # Do nothing unless the display has sufficient resolution.
    return unless isRetina()

    # Find the retina asset URL; either the value of the `at2x` attribute, if
    # given, or with '@2x' inserted just prior to the file extension.
    retinaSrc = ->
      return attrs.at2x if attrs.at2x
      chunks = attrs.src.split('.')
      # Give up if there is no file extension.
      return '' if chunks.length < 2
      # Otherwise, insert '@2x' just before the file extension.
      chunks[chunks.length - 2] += '@2x'
      chunks.join('.')

    # Do nothing if the retina asset is already loaded.
    src = retinaSrc()
    return if attrs.src is src

    # Load the retina asset and swap it out on success.
    preload(src, -> attrs.$set('src', src))
]


# Display a shuffle animation when changing values; based on an idea from
# <http://tutorialzine.com/2011/09/shuffle-letters-effect-jquery/>.
module.directive 'bindShuffle', ['$timeout', ($timeout) ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    firstTime = true
    shuffleTimer = undefined
    step = 8
    delay = 40
    randomChar = (characters) ->
      characters.charAt(Math.floor(Math.random() * characters.length))

    shuffle = (start, value) ->
      return if start > value.length
      shuffled = []
      for char, i in value
        if i < start
          shuffled.push(char)
        else if i < start + step
          shuffled.push(randomChar(value))
      elm.text(shuffled.join(''))
      shuffleTimer = $timeout((-> shuffle(start + 1, value)), delay)
      return  # throw away implicit return value

    scope.$watch attrs.bindShuffle, (value) ->
      # Don't animate the initial value.
      if firstTime
        firstTime = false
        return
      # Clear out any existing animations, then start shuffling one character
      # in at a time.
      $timeout.cancel(shuffleTimer)
      shuffle(-step, value)
]


# Provide a smooth scrolling animation to the given in-page href.
# TODO: Revisit this implementation; pulling in 25k of TweenLite is a bit
# excessive for some smooth scrolling.
module.directive 'smoothScroll', ['$window', ($window) ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    return unless attrs.href.indexOf('#') is 0
    id = attrs.href.slice(1)
    elm.bind 'click', (event) ->
      event.preventDefault()
      $window.TweenLite.to $window, .4,
        scrollTo: {y: yOffset($window.document.getElementById(id))}
        ease: $window.Power2.easeInOut
]


# One-off directive for handling an in-page slideshow controlled via scrolling.
# The idea is similar to some parallax-scrolling effects: the page's content
# height is computed as if the slides were positioned statically, then the body
# is set to be at least that tall (to provide enough scrolling "room"). The
# slides are stacked one on top of another and an element that wraps the entire
# page is affixed to the top of the viewport.
#
# On scroll, the wrapper element is offset upwards until the slideshow arrives
# at the top of the viewport. Then, each slide is offset upwards in turn until
# the last one, at which point the wrapper picks up the offset again.
module.directive 'slideshow', ['$window', ($window) ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    # Shared variables.
    slides = elm[0].querySelectorAll('.slide')
    return unless slides.length
    body = angular.element($window.document.body)
    bodyHeightSansSlides = slideHeight = extraSlidesHeight = null
    firstSlideTop = lastSlideTop = null
    wrapper = null

    # Stack each element in `elements` underneath its predecessor.
    descendingStackingOrder = (elements) ->
      angular.forEach elements, (element, i) ->
        angular.element(element).css(zIndex: elements.length - i)

    # TODO: Handle turning on/off slideshow on resize?
    adjustSizes = ->
      # Find the slide height and adjust the container.
      slideHeight = attrs.slides
      slideHeight or= $window.innerHeight
      slideHeight or= $window.document.documentElement.clientHeight  # IE8
      # If the viewport is too small or we're on Mobile Safari, abandon ship.
      # XXX check for mobile safari
      return false unless slideHeight and slideHeight > 600
      elm.css(height: "#{slideHeight}px")
      # Vertically center each slide.
      angular.forEach slides, (slide) ->
        slide = angular.element(slide)
        content = slide.children()[0]
        angular.element(content).css(marginTop: "-#{content.clientHeight}px")
        angular.element(slide).css(lineHeight: 'normal')
      # Find the offsets for the first and last animated slides.
      firstSlideTop or= yOffset(elm)
      extraSlidesHeight = (slides.length - 1) * slideHeight
      lastSlideTop = firstSlideTop + extraSlidesHeight
      # Ensure the page has enough room to scroll.
      bodyHeightSansSlides or= body[0].clientHeight - slideHeight
      body.css(minHeight: "#{bodyHeightSansSlides + slideHeight + extraSlidesHeight}px")
      x = bodyHeightSansSlides + slideHeight + extraSlidesHeight

    adjustScroll = ->
      y = $window.scrollY  # XXX ie?
      # Past the slideshow; make sure that all slides are scrolled up.
      if y >= lastSlideTop
        y -= extraSlidesHeight
        angular.forEach slides, (slide, i) ->
          return if i is slides.length - 1
          angular.element(slide).css(top: "#{slideHeight}px")
      # Inside the slideshow.
      else if y >= firstSlideTop
        relativeY = y - firstSlideTop
        currentSlide = Math.floor(relativeY / slideHeight)
        currentOffset = relativeY - (currentSlide * slideHeight)
        angular.forEach slides, (slide, i) ->
          offset = if i < currentSlide
            slideHeight
          else if i is currentSlide
            currentOffset
          else
            0
          angular.element(slide).css(top: "-#{offset}px")
        y = firstSlideTop  # don't scroll the container
      # Before the slideshow; make sure that all slides are reset.
      else
        angular.forEach slides, (slide) ->
          angular.element(slide).css('top', '0')
      wrapper.css(top: "-#{y}px")

    # Set everything up once images load, so we can compute the page height.
    angular.element($window).bind 'load', ->
      return unless adjustSizes()  # must happen before fixing the wrapper
      elm.addClass('slideshow')
      descendingStackingOrder(slides)
      wrapper = angular.element(document.querySelectorAll('.scroll-wrapper')).css
        position: 'fixed'
        left: '0'
        right: '0'
        top: '0'
      adjustScroll()
      angular.element($window).bind('resize', adjustSizes)
      angular.element($window).bind('scroll', adjustScroll)
]
