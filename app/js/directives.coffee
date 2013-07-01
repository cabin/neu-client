module = angular.module('neu.directives', [])

# Return the y-offset relative to the document for the given `element`, which
# can be an angular Element or a DOM node.
elementY = (element) ->
  return 0 unless element
  # Grab the first match if this is a wrapped element.
  element = element[0] if (element.bind and element.find)
  offset = element.offsetTop
  node = element
  while node.offsetParent and node.offsetParent isnt window.document.body
    node = node.offsetParent
    continue if node.offsetTop < 0  # account for crazy scroll-wrapper
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


# Provide a cross-browser HTML5 `placeholder` attribute implementation.
module.directive 'placeholder', [() ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    container = angular.element(document.createElement('div'))
    label = angular.element(document.createElement('label'))
    label.text(attrs.placeholder)
    elm.attr('placeholder', '')
    elmID = elm.attr('id')
    if not elmID
      elmID = "placeholder-id-#{elm.attr('name')}"  # XXX uniqueness!
      elm.attr('id', elmID)
    label.attr('for', elmID)
    # Update the DOM.
    elm.after(container)
    container.append(label)
    container.append(elm)
    container.addClass('placeholder')

    togglePlaceholder = ->
      showPlaceholder = elm.val() is ''
      container.toggleClass('placeholder--is-visible', showPlaceholder)

    elm.bind('change keydown cut paste', -> setTimeout(togglePlaceholder, 0))
    togglePlaceholder()
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
        scrollTo: {y: elementY($window.document.getElementById(id))}
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
    slides = elm[0].querySelectorAll('.slideshow__slide')
    return unless slides.length
    mask = angular.element(elm[0].querySelector('.slideshow__mask'))
    maskHeight = 600
    body = angular.element($window.document.body)
    bodyHeightSansSlides = slideHeight = extraSlidesHeight = null
    scrollWrapper = angular.element(document.querySelector('.js-scroll-wrapper'))
    contentWrapper = document.querySelector('.js-content-wrapper')
    slideWidth = startSlidesAt = startTransitionAt = endSlidesAt = null
    transitionMultiplier = 0.65
    showingSlides = false

    # If the viewport is too small or we're on a touch device, no slides.
    canShowSlides = ->
      return false unless slideHeight and slideHeight >= 600
      return false unless slideWidth >= 768
      return false if Modernizr.touch
      true

    enableSlideshow = ->
      elm.addClass('slideshow')
      descendingStackingOrder(slides)
      scrollWrapper.css
        position: 'fixed'
        left: '0'
        right: '0'
        top: '0'
      showingSlides = true

    disableSlideshow = ->
      elm.removeClass('slideshow')
      elm.removeAttr('style')
      mask.removeAttr('style')
      scrollWrapper.removeAttr('style')
      body.removeAttr('style')
      angular.forEach slides, (slide) ->
        slide = angular.element(slide)
        content = angular.element(slide.children()[0])
        slide.removeAttr('style')
        content.removeAttr('style')
      showingSlides = false

    # Stack each element in `elements` underneath its predecessor.
    descendingStackingOrder = (elements) ->
      angular.forEach elements, (element, i) ->
        angular.element(element).css(zIndex: elements.length - i)

    adjustSizes = ->
      # Find the slide height and adjust the container.
      previousSlideHeight = slideHeight
      slideHeight = attrs.slides
      slideHeight or= $window.innerHeight
      slideHeight or= $window.document.documentElement.clientHeight  # IE8
      slideWidth = elm[0].clientWidth
      if canShowSlides()
        enableSlideshow() unless showingSlides
      else
        disableSlideshow() if showingSlides
        return  # nothing else to do
      elm.css(height: "#{slideHeight}px")
      startTransitionAt = Math.floor(slideHeight * transitionMultiplier)
      # Vertically center each slide.
      angular.forEach slides, (slide) ->
        slide = angular.element(slide)
        contentEl = slide.children()[0]
        content = angular.element(contentEl)
        # Override table-cell display to get the correct height; two separate
        # calls to allow a reflow in between.
        content.css(display: 'block')
        content.css(marginTop: "-#{contentEl.clientHeight / 2}px")
        slide.css(width: "#{slideWidth}px")
      # Find the offsets for the first and last animated slides.
      startSlidesAt or= elementY(elm)
      # Include an extra `startTransitionAt` for a pause on the final slide.
      extraSlidesHeight = (slides.length - 1) * slideHeight + startTransitionAt
      endSlidesAt = startSlidesAt + extraSlidesHeight
      # Ensure the page has enough room to scroll.
      if bodyHeightSansSlides and previousSlideHeight isnt slideHeight
        bodyHeightSansSlides += slideHeight - previousSlideHeight
      bodyHeightSansSlides = contentWrapper.clientHeight - slideHeight
      minHeight = bodyHeightSansSlides + slideHeight + extraSlidesHeight
      body.css(minHeight: "#{minHeight}px")
      adjustScroll()

    # The slide transition only begins after scrolling `transitionMultiplier`
    # (as a percentage) through the slide; adjust the range to accommodate.
    rescale = (offset) ->
      originalRange = slideWidth - startTransitionAt
      ((offset - startTransitionAt) * slideWidth) / originalRange

    adjustScroll = ->
      return unless showingSlides
      y = $window.scrollY or $window.document.documentElement.scrollTop  # IE8
      # Past the slideshow; make sure that all slides are scrolled off.
      if y >= endSlidesAt
        y -= extraSlidesHeight
        angular.forEach slides, (slide, i) ->
          return if i is slides.length - 1
          angular.element(slide).css(left: "#{slideWidth}px")
        mask.css(top: "-#{maskHeight}px")
      # Inside the slideshow.
      else if y >= startSlidesAt
        relativeY = y - startSlidesAt
        currentSlide = Math.floor(relativeY / slideHeight)
        # It's possible for the computed current slide to exceed the total
        # slides due to the final slide's extra padding. Correct for this.
        currentSlide = Math.min(currentSlide, slides.length - 1)
        yOffset = relativeY - (currentSlide * slideHeight)
        xOffset = (yOffset / slideHeight) * slideWidth
        angular.forEach slides, (slide, i) ->
          # Previous slides are off the page.
          offset = if i < currentSlide
            slideWidth
          # The final slide never moves.
          else if i is slides.length - 1
            0
          # The current slide starts moving partway through its scrollHeight.
          else if i is currentSlide and xOffset >= startTransitionAt
            rescale(xOffset)
          else
            0
          angular.element(slide).css(left: "#{Math.floor(offset)}px")
          # XXX testing a swipe instead of slide; refactor or remove
          c = angular.element(angular.element(slide).children()[0])
          angular.element(slide).css(overflow: 'hidden')
          c.css(marginLeft: "-#{Math.floor(offset) * 2}px")
        y = startSlidesAt  # don't scroll the container
        mask.css(top: "-#{maskHeight}px")
      # Before the slideshow; make sure that all slides are reset.
      else
        angular.forEach slides, (slide) ->
          angular.element(slide).css(left: '0')
        # Slide the mask up to reveal the first slide.
        ratio = y / startSlidesAt
        mask.css(top: "-#{Math.floor(ratio * maskHeight)}px")
      scrollWrapper.css(top: "-#{y}px")

    setup = ->
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
      angular.element($window).bind('resize', debounce(adjustSizes, 100))
      angular.element($window).bind('scroll', adjustScroll)
      adjustSizes()
      adjustScroll()

    # Set everything up once images load, so we can compute the page height.
    angular.element($window).bind 'load', ->
      # If we loaded respond.js, give it time to update the page.
      if $window.respond?
        setTimeout(setup, 150)
      else
        setup()
]
