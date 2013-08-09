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
