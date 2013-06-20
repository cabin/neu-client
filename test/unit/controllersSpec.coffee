describe 'controllers', ->
  $scope = null

  beforeEach ->
    module('neu.controllers')

  describe 'SplashCtrl', ->
    preload = $timeout = null

    beforeEach ->
      module ($provide) ->
        preload = jasmine.createSpy('preload')
        $provide.factory('preload', -> preload)
        return null
      inject ($controller, $rootScope, _$timeout_) ->
        $scope = $rootScope.$new()
        $controller('SplashCtrl', $scope: $scope)
        $timeout = _$timeout_

    it 'should preload all necessary images', ->
      expect(preload.calls.length).toEqual(2)

    it 'should cycle through the data', ->
      initialSel = $scope.sel
      $timeout.flush()
      expect($scope.sel).not.toEqual(initialSel)

    it 'should wrap to the beginning of the data when reaching the end', ->
      initialSel = $scope.sel
      wrapped = false
      for i in [1..5]
        $timeout.flush()
        if $scope.sel is initialSel
          wrapped = true
          break
      expect(wrapped).toBe(true)

  describe 'TeamCtrl', ->
    beforeEach ->
      inject ($controller, $rootScope) ->
        $scope = $rootScope.$new()
        $controller('TeamCtrl', $scope: $scope)

    it 'should advance the index on next()', ->
      expect($scope.index).toEqual(0)
      $scope.next()
      expect($scope.index).toEqual(1)

    it 'should reduce the index on prev()', ->
      expect($scope.index).toEqual(0)
      $scope.next()
      $scope.prev()
      expect($scope.index).toEqual(0)

    it 'should wrap the index correctly', ->
      expect($scope.index).toEqual(0)
      $scope.prev()
      expect($scope.index).toEqual($scope.sectionCount - 1)

    it 'should set the animation direction correctly', ->
      $scope.next()
      expect($scope.animate()).toEqual('team-left')
      $scope.prev()
      expect($scope.animate()).toEqual('team-right')

  describe 'JoinCtrl', ->
    beforeEach ->
      inject ($controller, $rootScope) ->
        $scope = $rootScope.$new()
        $controller('JoinCtrl', $scope: $scope)

    xit 'should validate and submit the form'  # TODO
