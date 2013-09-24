describe 'scrolling', ->

  beforeEach ->
    module('neu.scrolling')

  describe 'getScrollTop', ->
    getScrollTop = null
    $window = null

    beforeEach ->
      $window = {}
      module ($provide) ->
        $provide.factory('$window', -> $window)
        return

    # Because branching happens at injection time rather than call time, we
    # have to re-inject for each test.
    injectGetScrollTop = ->
      inject ($injector) -> getScrollTop = $injector.get('getScrollTop')

    it 'returns pageYOffset if available', ->
      $window.pageYOffset = 12
      injectGetScrollTop()
      expect(getScrollTop()).toEqual(12)

    it 'provides a fallback for IE', ->
      $window.document = documentElement: scrollTop: 17
      injectGetScrollTop()
      expect(getScrollTop()).toEqual(17)

    it 'prefers pageYOffset', ->
      $window.pageYOffset = 12
      $window.document = documentElement: scrollTop: 17
      injectGetScrollTop()
      expect(getScrollTop()).toEqual(12)
