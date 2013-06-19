describe 'directives', ->
  beforeEach ->
    module('neu.services')
    module('neu.directives')

  describe 'at2x', ->
    $compile = $rootScope = wantsRetina = preload = preloadSuccess = null

    beforeEach ->
      module ($provide) ->
        # Toggle `wantsRetina` in a test to affect `isRetina` behavior.
        wantsRetina = true
        $provide.value('isRetina', -> wantsRetina)
        # Toggle `preloadSuccess` in a test to affect `preload` behavior.
        preloadSuccess = true
        fakePreload = (src, success) -> success() if preloadSuccess
        preload = jasmine.createSpy('preload').andCallFake(fakePreload)
        $provide.factory('preload', -> preload)
        return null
      inject (_$compile_, _$rootScope_) ->
        $compile = _$compile_
        $rootScope = _$rootScope_

    it 'should preload the specified asset', ->
      element = $compile('<img at2x="bar">')($rootScope)
      expect(preload).toHaveBeenCalledWith('bar', jasmine.any(Function))

    it 'should swap the asset on successful preload', ->
      element = $compile('<img src="foo" at2x="bar">')($rootScope)
      expect(element.attr('src')).toEqual('bar')

    it 'should attempt to guess the asset name when not given', ->
      element = $compile('<img src="foo.png" at2x>')($rootScope)
      expect(element.attr('src')).toEqual('foo@2x.png')

    it 'should not swap the asset on failed preload', ->
      preloadSuccess = false
      element = $compile('<img src="foo" at2x="bar">')($rootScope)
      expect(element.attr('src')).toEqual('foo')

    it 'should do nothing on non-retina displays', ->
      wantsRetina = false
      element = $compile('<img src="foo" at2x="bar">')($rootScope)
      expect(preload).not.toHaveBeenCalled()
      expect(element.attr('src')).toEqual('foo')

  describe 'bindShuffle', ->
    xit 'should have some tests :('  # TODO

  describe 'smoothScroll', ->
    xit 'should have some tests :('  # TODO
