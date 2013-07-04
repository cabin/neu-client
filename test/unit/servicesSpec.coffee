describe 'services', ->
  $window = {}

  beforeEach ->
    module('neu.services')
    # Clean up the fake window object.
    for key of $window
      delete $window[key]
    module ($provide) ->
      $provide.factory('$window', -> $window)
      return null

  describe 'isRetina', ->
    isRetina = matchMedia = null

    beforeEach ->
      inject ($injector) ->
        isRetina = $injector.get('isRetina')
        matchMedia = matches: false
        $window.matchMedia = jasmine.createSpy().andReturn(matchMedia)

    it 'checks devicePixelRatio', ->
      $window.devicePixelRatio = 1.5
      expect(isRetina()).toBe(true)
      expect($window.matchMedia).not.toHaveBeenCalled()
      $window.devicePixelRatio = 1
      expect(isRetina()).toBe(false)

    it 'falls back on a media query', ->
      $window.devicePixelRatio = undefined
      expect(isRetina()).toBe(false)
      matchMedia.matches = true
      expect(isRetina()).toBe(true)

    it 'is false when the browser lacks devicePixelRatio and matchMedia', ->
      $window.devicePixelRatio = undefined
      $window.matchMedia = undefined
      expect(isRetina()).toBe(false)

  describe 'preload', ->
    preload = img = null

    beforeEach ->
      inject ($injector) ->
        preload = $injector.get('preload')
        img = {}
        $window.Image = jasmine.createSpy('Image').andReturn(img)

    it 'loads the given image', ->
      preload('test.png')
      expect(img.src).toEqual('test.png')

    it 'calls the success arg when appropriate', ->
      fn = ->
      preload('test.png', fn)
      expect(img.onload).toEqual(fn)

    it 'calls the error arg when appropriate', ->
      fn = ->
      preload('test.png', undefined, fn)
      expect(img.onload).toBe(undefined)
      expect(img.onerror).toEqual(fn)

  describe 'getScrollTop', ->
    getScrollTop = null

    beforeEach = ->
      $window = document: documentElement: {}

    # Because branching happens at injection time rather than call time, we
    # have to re-inject for each test.
    injectScrollTop = ->
      inject ($injector) -> getScrollTop = $injector.get('getScrollTop')

    it 'returns scrollY if available', ->
      $window.scrollY = 12
      injectScrollTop()
      expect(getScrollTop()).toEqual(12)

    it 'provides a fallback for IE', ->
      $window.document = documentElement: scrollTop: 17
      injectScrollTop()
      expect(getScrollTop()).toEqual(17)

    it 'does not fall back when scrollY is available', ->
      $window.scrollY = 12
      $window.document = documentElement: scrollTop: 17
      injectScrollTop()
      expect(getScrollTop()).toEqual(12)
