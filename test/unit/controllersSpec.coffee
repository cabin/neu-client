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
      expect(preload.calls.length).toEqual(6)

    it 'should cycle through the data', ->
      initialSel = $scope.sel
      $timeout.flush()
      expect($scope.sel).not.toEqual(initialSel)

    it 'should wrap to the beginning of the data when reaching the end', ->
      initialSel = $scope.sel
      wrapped = false
      for i in [1..7]
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
    $window = $httpBackend = null

    beforeEach ->
      inject ($controller, $rootScope, _$window_, _$httpBackend_) ->
        $scope = $rootScope.$new()
        $scope.form = jasmine.createSpy('$scope.form')
        $controller('JoinCtrl', $scope: $scope)
        $window = _$window_
        $window.ga = jasmine.createSpy('$window.ga')
        $httpBackend = _$httpBackend_

    afterEach ->
      $httpBackend.verifyNoOutstandingExpectation()
      $httpBackend.verifyNoOutstandingRequest()

    it 'should initially have no special state', ->
      for _, value of $scope.state
        expect(value).toBe(false)

    describe '$scope.submit', ->
      submitValid = ->
        $scope.form.$valid = true
        $httpBackend.expectPOST('/api/prospects').respond(201, '')
        $scope.submit()
        $httpBackend.flush()

      it 'should submit the form if it is valid', ->
        submitValid()

      it 'should track an event with Google Analytics', ->
        submitValid()
        expect($window.ga).toHaveBeenCalledWith(
          'send', 'event', jasmine.any(String), jasmine.any(String))

      it "should mark state as invalid when the form isn't valid", ->
        $scope.form.$valid = false
        $scope.submit()
        expect($scope.state.invalid).toBe(true)

      it 'should not submit or track an invalid submission', ->
        $scope.form.$valid = false
        $scope.submit()
        expect($window.ga).not.toHaveBeenCalled()

      it 'should prevent multiple submissions', ->
        submitValid()
        $httpBackend.resetExpectations()
        $scope.submit()
        $scope.submit()

      it 'should note a failed POST', ->
        $scope.form.$valid = true
        $httpBackend.expectPOST('/api/prospects').respond(500, '')
        $scope.submit()
        $httpBackend.flush()
        expect($scope.state.submissionFailed).toBe(true)
