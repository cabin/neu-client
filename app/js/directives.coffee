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


# Based on Prototype's implementation; get the `id` of the given `element`,
# generating one first if necessary.
idCounter = 1
identify = (element) ->
  id = element.attr('id')
  return id if id
  id = 'placeholder-id-' + idCounter++
  while document.getElementById(id)
    id = 'placeholder-id-' + idCounter++
  element.attr('id', id)
  return id


# Algorithm from underscore.js.
sortedIndex = (array, obj) ->
  [low, high] = [0, array.length]
  while low < high
    mid = (low + high) >>> 1
    if array[mid] < obj then low = mid + 1 else high = mid
  return low


# Shuffle an array, Fisher-Yates style.
shuffle = (array) ->
  i = array.length
  while --i
    j = Math.floor(Math.random() * (i + 1))
    [array[i], array[j]] = [array[j], array[i]]
  array


# Tween the page to the new scroll position.
scrollSmoothly = (to) ->
  TweenLite.to(window, .4, scrollTo: {y: to}, ease: Power2.easeInOut)


# For images with an `at2x` attribute, and only on retina displays, attempt to
# load a retina asset (<filename>@2x.<ext>) and swap it out for the existing
# asset on success.
module.directive 'neuAt2x', ['isRetina', 'preload', (isRetina, preload) ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    # Do nothing unless the display has sufficient resolution.
    return unless isRetina()

    # Find the retina asset URL; either the value of the `at2x` attribute, if
    # given, or with '@2x' inserted just prior to the file extension.
    retinaSrc = ->
      return attrs.neuAt2x if attrs.neuAt2x
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
module.directive 'placeholder', ['$timeout', ($timeout) ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    return if Modernizr?.placeholder
    container = null
    createElements = ->
      container = angular.element(document.createElement('div'))
      label = angular.element(document.createElement('label'))
      label.text(attrs.placeholder)
      elm.attr('placeholder', '')
      label.attr('for', identify(elm))
      # Update the DOM.
      elm.after(container)
      container.append(label)
      container.append(elm)
      container.addClass('placeholder')

    togglePlaceholder = ->
      showPlaceholder = elm.val() is ''
      container.toggleClass('placeholder--is-visible', showPlaceholder)

    createElements()
    elm.bind('change keydown cut paste', -> $timeout(togglePlaceholder, 0))
    togglePlaceholder()
]


# Display a shuffle animation when changing values; based on an idea from
# <http://tutorialzine.com/2011/09/shuffle-letters-effect-jquery/>.
module.directive 'neuBindShuffle', ['$timeout', ($timeout) ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    firstTime = true
    shuffleTimer = undefined
    step = 8
    delay = 40
    randomChar = (characters) ->
      characters.charAt(Math.floor(Math.random() * characters.length))

    shuffleChars = (start, value) ->
      return if start > value.length
      shuffled = []
      for char, i in value
        if i < start
          shuffled.push(char)
        else if i < start + step
          shuffled.push(randomChar(value))
      elm.text(shuffled.join(''))
      shuffleTimer = $timeout((-> shuffleChars(start + 1, value)), delay)
      return  # throw away implicit return value

    scope.$watch attrs.neuBindShuffle, (value) ->
      # Don't animate the initial value.
      if firstTime
        firstTime = false
        return
      # Clear out any existing animations, then start shuffling one character
      # in at a time.
      $timeout.cancel(shuffleTimer)
      shuffleChars(-step, value)
]


# Provide a smooth scrolling animation to the given in-page href.
# TODO: Revisit this implementation; pulling in 25k of TweenLite is a bit
# excessive for some smooth scrolling.
module.directive 'neuSmoothScroll', ['$window', ($window) ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    return unless attrs.href.indexOf('#') is 0
    id = attrs.href.slice(1)
    elm.bind 'click', (event) ->
      event.preventDefault()
      scrollSmoothly(elementY($window.document.getElementById(id)))
]


# One-off directive for handling an in-page slideshow controlled via scrolling.
# The idea is similar to some parallax-scrolling effects: the page's content
# height is computed as if the slides were positioned statically, then the body
# is set to be at least that tall (to provide enough scrolling "room"). The
# slides are stacked one on top of another and an element that wraps the entire
# page is affixed to the top of the viewport.
#
# On scroll, the wrapper element is offset upwards until the slideshow arrives
# at the top of the viewport. Then, scrolling produces no visible effect
# between slide thresholds, at which point the slide is animated off the
# screen. After the last slide, the wrapper picks up the offset again.
module.directive 'neuSlideshow', ['$window', '$timeout', ($window, $timeout) ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    # Shared variables.
    slides = angular.element(elm[0].querySelectorAll('.slideshow__slide'))
    return unless slides.length
    # HTML elements.
    body = angular.element($window.document.body)
    scrollWrapper = angular.element(document.querySelector('.js-scroll-wrapper'))
    contentWrapper = document.querySelector('.js-content-wrapper')
    mask = angular.element(elm[0].querySelector('.slideshow__mask'))
    # Sizes and positions.
    pageWidth = maskHeight = scrollOffsets = slideOffsets = null
    # Configuration.
    slideDuration = .2
    maxScrollPerSlide = 800

    scope.slideshowEnabled = false
    scope.nextSlide = ->
      pos = currentSegment(scrollOffsets, scope.page.scroll)
      pos = Math.min(pos + 1, scrollOffsets.length - 1)
      # Snap to next slide in the slideshow; animate elsewhere.
      if 1 < pos < slides.length + 1
        $window.scrollTo(0, scrollOffsets[pos])
      else
        scrollSmoothly(scrollOffsets[pos])

    scope.previousSlide = ->
      pos = currentSegment(scrollOffsets, scope.page.scroll)
      pos = Math.max(pos - 1, 0)
      # Safe to smooth scroll everywhere, since the slide transition point is
      # on the front side of the animation.
      return scrollSmoothly(scrollOffsets[pos])

    # Return the index into scrollOffsets whose value is immediately previous
    # to the given value (that is, find which "chunk" y should be showing).
    currentSegment = (array, obj) ->
      # sortedIndex just ensures the array remains sorted, while we are using
      # each point in the array as a threshold and want to know in which
      # segment we belong.
      pos = sortedIndex(array, obj)
      pos -= 1 unless obj is array[pos]
      return pos

    # If the viewport is too small or we're on a touch device, no slides.
    canShowSlides = (w, h) ->
      return false unless h and h >= 600 and w > 768
      return false if Modernizr.touch
      true

    enableSlideshow = ->
      scrollWrapper.css
        position: 'fixed'
        left: '0'
        right: '0'
        top: '0'
      elm.addClass('slideshow')
      descendingStackingOrder(slides)
      # Vertically center each slide; assumes a single child element.
      angular.forEach slides, (slide) ->
        slide = angular.element(slide)
        contentEl = slide.children()[0]
        content = angular.element(contentEl)
        # Override table-cell display to get the correct height; two separate
        # calls to force a reflow in between.
        content.css(display: 'block')
        content.css(marginTop: "-#{contentEl.clientHeight / 2}px")
      scope.slideshowEnabled = true

    # Older webkit fails to actually remove styles when removing the `style`
    # attribute; setting it to the empty string first is a workaround.
    removeStyle = (element) ->
      element.attr('style', '')
      element.removeAttr('style')

    disableSlideshow = ->
      elm.removeClass('slideshow')
      removeStyle(elm)
      removeStyle(mask)
      removeStyle(scrollWrapper)
      removeStyle(body)
      angular.forEach slides, (slide) ->
        slide = angular.element(slide)
        content = angular.element(slide.children()[0])
        removeStyle(slide)
        removeStyle(content)
      scope.slideshowEnabled = false

    # Stack each element in `elements` underneath its predecessor.
    descendingStackingOrder = (elements) ->
      angular.forEach elements, (element, i) ->
        angular.element(element).css(zIndex: elements.length - i)

    # Tween `slide` to the given `offset`, which should be a string including
    # the unit (usually `px`).
    animateSlide = (slide, offset) ->
      return if slide.tweening  # one tween at a time per slide
      slide.tweening = true
      content = angular.element(slide).children()[0]
      new $window.TimelineLite
        autoRemoveChildren: true
        onComplete: -> slide.tweening = false
        tweens: [
          $window.TweenLite.to slide, slideDuration,
            left: offset
            ease: $window.Linear.easeNone
          $window.TweenLite.to content, slideDuration,
            left: "-#{offset}"
            ease: $window.Linear.easeNone
        ]

    # Called on window resize.
    adjustSizes = (pw, pageHeight) ->
      pageWidth = pw  # global

      # Enable/disable the slideshow based on the computed dimensions.
      if canShowSlides(pageWidth, pageHeight)
        enableSlideshow() unless scope.slideshowEnabled
      else
        disableSlideshow() if scope.slideshowEnabled
        return  # nothing else to do

      # Fix the container and slide sizes.
      elm.css(height: "#{pageHeight}px")
      slides.css(width: "#{pageWidth}px")
      slideScroll = Math.min(pageHeight, maxScrollPerSlide)

      # slideOffsets records the top of each slide and the "bottom" of the
      # final slide (the point at which page scroll should be unlocked).
      # scrollOffsets records the top of the page, the top of each slide, and
      # the point at which the slideshow has been completely scrolled off the
      # page (in other words, the top of the next element).
      slideshowTop = elementY(elm)
      slideOffsets = []
      angular.forEach slides, (_, i) ->
        slideOffsets.push(slideshowTop + slideScroll * i)
      scrollOffsets = [0].concat(slideOffsets)
      slideOffsets.push(slideOffsets[slideOffsets.length - 1] + slideScroll)
      scrollOffsets.push(slideOffsets[slideOffsets.length - 1] + pageHeight)

      # Ensure the mask covers the slideshow.
      maskHeight = pageHeight - slideshowTop
      mask.css(height: "#{maskHeight}px")

      # Ensure the page has enough room to scroll.
      minHeight = contentWrapper.clientHeight + slides.length * slideScroll
      body.css(minHeight: "#{minHeight}px")
      adjustScroll()

    # Called on scroll.
    adjustScroll = (y) ->
      return unless scope.slideshowEnabled  # nothing to do
      currentSlide = currentSegment(slideOffsets, y)

      # Before the first slide.
      if currentSlide < 0
        # Slide the mask up to reveal the first slide.
        ratio = y / slideOffsets[0]
        mask.css(top: "-#{Math.floor(ratio * maskHeight)}px")
        # Reset slides.
        slides.css(left: '0')
        angular.forEach slides, (slide) ->
          content = angular.element(angular.element(slide).children()[0])
          content.css(left: '0')

      # Inside the slideshow.
      else if currentSlide < slides.length
        y = slideOffsets[0]  # don't scroll the container
        mask.css(top: "-#{maskHeight}px")
        angular.forEach slides, (slide, i) ->
          return if i is slides.length - 1  # last slide doesn't animate
          offset = "#{if i >= currentSlide then 0 else pageWidth}px"
          # Don't re-animate if the slide is already in position.
          return if angular.element(slide).css('left') is offset
          animateSlide(slide, offset)

      # After the last slide.
      else
        # Remove slide height from scrollWrapper's offset.
        y -= slideOffsets[slides.length] - slideOffsets[0]
        mask.css(top: "-#{maskHeight}px")
        # Slide off all slides.
        angular.forEach slides, (slide, i) ->
          return if i is slides.length - 1
          slide = angular.element(slide)
          content = angular.element(slide.children()[0])
          slide.css(left: "#{pageWidth}px")
          content.css(left: "-#{pageWidth}px")

      # Scroll the page.
      scrollWrapper.css(top: "-#{y}px")

    setup = ->
      y = scope.page.scroll
      $timeout((-> $window.scrollTo(0, y)), 0) if y

      scope.$watch(
        '[page.width, page.height]',
        ((value) -> adjustSizes(value[0], value[1])),
        true)
      scope.$watch('page.scroll', adjustScroll)
      scope.$digest()
      angular.element($window.document).bind('keydown', keydownHandler)

    # Try to improve slideshow experience for users paging with a keyboard.
    keydownHandler = (event) ->
      return unless scope.slideshowEnabled
      # Ignore modified keypresses.
      return if event.shiftKey or event.metaKey or event.altKey or event.ctrlKey
      y = scope.page.scroll
      # Don't take over scrolling beyond the slideshow.
      return unless y < scrollOffsets[scrollOffsets.length - 1]
      if event.keyCode is 33  # pgup
        scope.previousSlide()
        event.preventDefault()
      else if event.keyCode in [32, 34]  # space, pgdn
        scope.nextSlide()
        event.preventDefault()

    # Set everything up once images load, so we can compute the page height.
    angular.element($window).bind 'load', ->
      # If we loaded respond.js, give it time to update the page.
      if $window.respond?
        setTimeout(setup, 150)
      else
        setup()
]


# One-off directive for creating an animation at the end of the slideshow.
module.directive 'neuPostSlides', ['$window', ($window) ->
  restrict: 'A'
  link: (scope, elm, attrs) ->
    # Set up the text sprinkle.
    fromColor = '#e3e3e3'
    toColor = '#fc6138'
    chars = []

    # Don't sprinkle text on Mobile Safari; suspension of scripts while
    # scrolling makes it feel awkward.
    if Modernizr.touch
      elm.css(color: toColor)
    else
      angular.forEach elm[0].childNodes, (node) ->
        return unless node.nodeType is 3  # Node.TEXT_NODE
        frag = document.createDocumentFragment()
        angular.forEach node.nodeValue, (c) ->
          text = document.createTextNode(c)
          if c.match(/\s/)
            frag.appendChild(text)
          else
            span = document.createElement('span')
            span.style.color = fromColor
            span.appendChild(text)
            frag.appendChild(span)
            chars.push(span)
        chars = shuffle(chars)
        angular.element(node).replaceWith(frag)

    # Page elements; I feel dirty for reaching outside the directive. :/
    scrollWrapper = angular.element(document.querySelector('.js-scroll-wrapper'))
    scrollHint = angular.element(document.getElementById('js-scroll-hint'))

    target = 0
    findTarget = (pageHeight) ->
      target = elementY(elm) - (pageHeight - 100)

    checkScroll = (value) ->
      y = Math.abs(parseInt(scrollWrapper.css('top'), 10))
      y or= value
      sprinkle() if not sprinkled and y >= target
      desprinkle() if sprinkled and y <= target - 200

    timeline = null
    sprinkled = false
    sprinkle = ->
      sprinkled = true
      tweens = []
      if not Modernizr.touch
        angular.forEach chars, (char) ->
          tweens.push($window.TweenLite.to(char, .3, {color: toColor}))
      timeline = new $window.TimelineLite
        autoRemoveChildren: true
        tweens: tweens
        align: 'start'
        stagger: .04
      timeline.add(-> scrollHint.addClass('is-visible'))

    desprinkle = ->
      timeline.kill?()
      scrollHint.removeClass('is-visible')
      angular.element(chars).css(color: fromColor)
      sprinkled = false

    setup = ->
      scope.$watch('page.height', findTarget)
      scope.$watch('page.scroll', checkScroll)

    setTimeout(setup, 500)  # allow time for slideshow setup
]
