describe 'services', ->
  $window = null

  beforeEach ->
    module('neu.services')
    inject (_$window_) ->
      $window = _$window_

  describe 'isRetina', ->
    isRetina = matchMedia = null

    # TODO: test fails in Firefox; window.devicePixelRatio doesn't accept assignment
    beforeEach ->
      inject ($injector) ->
        isRetina = $injector.get('isRetina')
        matchMedia = matches: false
        spyOn($window, 'matchMedia').andReturn(matchMedia)

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
