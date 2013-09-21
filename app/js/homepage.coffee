angular.module('neu.homepage', ['neu.scrolling', 'cabin.preload'])

  # Allow the partner overlay to signal the splash controller.
  .factory('overlayComplete', ($q) -> $q.defer())

  .controller 'SplashCtrl', ($scope, $timeout, overlayComplete) ->
    shuffleText = [
      'Makers'
      'Thinkers'
      'Creators'
      'Engineers'
    ]
    delay = 2000
    index = -1
    cycle = ->
      index += 1
      if index >= shuffleText.length
        return  # one pass
      $scope.current = shuffleText[index]
      $timeout(cycle, delay)
      return
    #XXX when we re-enable the overlay...
    #overlayComplete.promise.then(cycle)
    cycle()

  .controller 'PartnerOverlayCtrl', ($window, $scope, $timeout, overlayComplete, preload) ->
    if not $window.localStorage
      overlayComplete.resolve()
      return
    key = 'lastVisit'
    lastVisit = parseInt($window.localStorage.getItem(key) or 0, 10)
    now = (new Date).getTime()
    delta = now - lastVisit
    $scope.show = delta > 1000 * 60 * 60 * 24  # one day in ms
    $window.localStorage.setItem(key, now)

    hideOverlay = ->
      $scope.show = false
      overlayComplete.resolve()

    if $scope.show
      # Wait for the background image to load before snatching it away.
      f = -> $timeout(hideOverlay, 2500)
      preload('/img/universe-long.jpg').then(f, f)
    else
      overlayComplete.resolve()

  # Display a shuffle animation when changing values; based on an idea from
  # <http://tutorialzine.com/2011/09/shuffle-letters-effect-jquery/>.
  .directive 'neuBindShuffle', ($timeout) ->
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


  # One-off directive for handling an in-page slideshow controlled via
  # scrolling. The slideshow container's height is set to provide scrolling
  # "room" for all of the contained slides. Each slide is sized to fill the
  # viewport exactly, then all slides are stacked with the first slide on top.
  #
  # On scroll, if the slideshow container is visible, adjust the visible slide
  # based on scroll progress through the container.
  .directive 'neuSlideshow', ($window, $timeout, elementY, scrollTo, fixedHeaderHeight) ->
    restrict: 'A'
    link: (scope, elm, attrs) ->
      # Shared variables.
      slides = angular.element(elm[0].querySelectorAll('.slideshow__slide'))
      return unless slides.length
      # HTML elements.
      siteHeader = angular.element(document.querySelector('.site-header'))
      mask = angular.element(elm[0].querySelector('.slideshow__curtain'))
      container = angular.element(elm[0].querySelector('.slideshow__slides'))
      # Sizes and positions.
      pageWidth = maskHeight = scrollOffsets = slideOffsets = slideScroll = null
      # Configuration.
      slideDuration = .2
      maxScrollPerSlide = 800

      scope.slideshowEnabled = false
      scope.nextSlide = ->
        pos = currentSegment(scrollOffsets, scope.viewport.scroll)
        pos = Math.min(pos + 1, scrollOffsets.length - 1)
        # Snap to next slide in the slideshow; animate elsewhere.
        if 1 < pos < slides.length + 1
          $window.scrollTo(0, scrollOffsets[pos])
        else
          scrollTo(scrollOffsets[pos])

      scope.previousSlide = ->
        pos = currentSegment(scrollOffsets, scope.viewport.scroll)
        pos = Math.max(pos - 1, 0)
        # Safe to smooth scroll everywhere, since the slide transition point is
        # on the front side of the animation.
        return scrollTo(scrollOffsets[pos])

      # Return the index into scrollOffsets whose value is immediately previous
      # to the given value (that is, find which "chunk" y should be showing).
      currentSegment = (array, obj) ->
        # Algorithm from underscore.js.
        sortedIndex = (array, obj) ->
          [low, high] = [0, array.length]
          while low < high
            mid = (low + high) >>> 1
            if array[mid] < obj then low = mid + 1 else high = mid
          return low
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
        elm.addClass('slideshow')
        siteHeader.css(position: 'absolute')
        fixedHeaderHeight.set(0)
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
        removeStyle(siteHeader)
        removeStyle(mask)
        removeStyle(container)
        fixedHeaderHeight.reset()
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
      adjustSizes = (pw, viewportHeight) ->
        pageWidth = pw  # global
        slideshowTop = elementY(elm)

        # Ensure the mask reaches the bottom of the first viewport.
        maskHeight = viewportHeight - slideshowTop
        mask.css(height: "#{maskHeight}px") if maskHeight > 0
        # Correct our later calculations if maskHeight is under its min-height.
        maskHeight = Math.max(maskHeight, mask[0].clientHeight)

        # Enable/disable the slideshow based on the computed dimensions.
        if canShowSlides(pageWidth, viewportHeight)
          enableSlideshow() unless scope.slideshowEnabled
        else
          disableSlideshow() if scope.slideshowEnabled
          return  # nothing else to do

        # Fix the container and slide sizes.
        slideScroll = Math.min(viewportHeight, maxScrollPerSlide)
        slideshowHeight = slideScroll * slides.length + viewportHeight
        elm.css(height: "#{slideshowHeight}px")
        container.css(height: "#{viewportHeight}px")

        # slideOffsets records the top of each slide and the "bottom" of the
        # final slide (the point at which page scroll should be unlocked).
        # scrollOffsets records the top of the page, the top of each slide, and
        # the point at which the slideshow has been completely scrolled off the
        # page (in other words, the top of the next element).
        slideOffsets = []
        angular.forEach slides, (_, i) ->
          slideOffsets.push(slideshowTop + slideScroll * i)
        scrollOffsets = [0].concat(slideOffsets)
        slideOffsets.push(slideOffsets[slideOffsets.length - 1] + slideScroll)
        scrollOffsets.push(slideOffsets[slideOffsets.length - 1] + viewportHeight)

        adjustScroll()

      # Called on scroll.
      adjustScroll = (y) ->
        return unless scope.slideshowEnabled and y?  # nothing to do
        currentSlide = currentSegment(slideOffsets, y)

        # Before the first slide.
        if currentSlide < 0
          # Slide the mask up to reveal the first slide.
          ratio = y / slideOffsets[0]
          mask.css(top: "-#{Math.floor(ratio * maskHeight)}px")
          container.css(position: 'absolute', top: 0)
          # Reset slides.
          slides.css(left: '0')
          angular.forEach slides, (slide) ->
            content = angular.element(angular.element(slide).children()[0])
            content.css(left: '0')

        # Inside the slideshow.
        else if currentSlide < slides.length
          mask.css(top: "-#{maskHeight}px")
          container.css(position: 'fixed', top: 0)
          angular.forEach slides, (slide, i) ->
            return if i is slides.length - 1  # last slide doesn't animate
            offset = "#{if i >= currentSlide then 0 else pageWidth}px"
            # Don't re-animate if the slide is already in position.
            return if angular.element(slide).css('left') is offset
            animateSlide(slide, offset)

        # After the last slide.
        else
          mask.css(top: "-#{maskHeight}px")
          container.css(position: 'absolute', top: 'auto', bottom: 0)
          # Slide off all slides.
          angular.forEach slides, (slide, i) ->
            return if i is slides.length - 1
            slide = angular.element(slide)
            content = angular.element(slide.children()[0])
            slide.css(left: "#{pageWidth}px")
            content.css(left: "-#{pageWidth}px")

      setup = ->
        scope.$watch(
          '[viewport.width, viewport.height]',
          ((value) -> adjustSizes(value[0], value[1])),
          true)
        scope.$watch('viewport.scroll', adjustScroll)
        scope.$digest()
        scope.$emit('slideshowLoaded')
        angular.element($window.document).bind('keydown', keydownHandler)

      # Try to improve slideshow experience for users paging with a keyboard.
      keydownHandler = (event) ->
        return unless scope.slideshowEnabled
        # Ignore modified keypresses.
        return if event.shiftKey or event.metaKey or event.altKey or event.ctrlKey
        y = scope.viewport.scroll
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


  # One-off directive for creating an animation at the end of the slideshow.
  .directive 'neuPostSlides', ($window, $timeout, elementY) ->
    restrict: 'A'
    link: (scope, elm, attrs) ->
      # Set up the text sprinkle.
      toColor = '#ff6138'
      chars = []

      # Shuffle an array, Fisher-Yates style.
      shuffle = (array) ->
        i = array.length
        while --i
          j = Math.floor(Math.random() * (i + 1))
          [array[i], array[j]] = [array[j], array[i]]
        array

      angular.forEach elm[0].childNodes, (node) ->
        return unless node.nodeType is 3  # Node.TEXT_NODE
        frag = document.createDocumentFragment()
        angular.forEach node.nodeValue, (c) ->
          text = document.createTextNode(c)
          if c.match(/\s/)
            frag.appendChild(text)
          else
            span = document.createElement('span')
            span.appendChild(text)
            frag.appendChild(span)
            chars.push(span)
        chars = shuffle(chars)
        angular.element(chars).addClass('sprinkle-text')
        angular.element(node).replaceWith(frag)

      # Page elements; I feel dirty for reaching outside the directive. :/
      scrollHint = angular.element(document.getElementById('js-scroll-hint'))

      target = 0
      findTarget = (viewportHeight) ->
        target = elementY(elm) - (viewportHeight - 100)

      checkScroll = (y) ->
        sprinkle() if not sprinkled and y >= target
        desprinkle() if sprinkled and y <= target - 200

      timeline = null
      sprinkled = false
      sprinkle = ->
        sprinkled = true
        tweens = []
        duration = .3
        stagger = .04
        delay = 0
        # Mobile Safari needs to use a CSS animation here since scripts are
        # suspended while scrolling; other platforms get the standard
        # tween/timeline.
        if Modernizr.touch
          addClass = (el) ->
            angular.element(el).addClass('sprinkle-text--active')
          angular.forEach chars, (char, i) ->
            $timeout((-> addClass(char)), stagger * i * 1000)
          delay = stagger * chars.length + duration
        else
          angular.forEach chars, (char) ->
            tweens.push($window.TweenLite.to(char, duration, {color: toColor}))
        timeline = new $window.TimelineLite
          autoRemoveChildren: true
          tweens: tweens
          align: 'start'
          stagger: stagger
          delay: delay
        timeline.add ->
          scrollHint.addClass('is-visible')
          $window.TweenLite.set(scrollHint, {scale: 0, height: 0})
        timeline.add($window.TweenLite.to(scrollHint, .25, {scale: 1}))
        timeline.add($window.TweenLite.to(scrollHint, .25, {height: '150px'}))

      desprinkle = ->
        timeline.kill?()
        scrollHint.removeClass('is-visible')
        angular.element(chars).removeClass('sprinkle-text--active')
        angular.element(chars).css(color: '')
        sprinkled = false

      # Wait for the slideshow to load, since it may adjust target offset.
      scope.$on 'slideshowLoaded', ->
        scope.$watch('viewport.height', findTarget)
        scope.$watch('viewport.scroll', checkScroll)
        scope.$digest()
