describe 'controllers', ->
  $scope = null

  beforeEach ->
    module('neu.rfi')

  describe 'RfiCtrl', ->
    $window = $httpBackend = null

    beforeEach ->
      inject ($controller, $rootScope, _$window_, _$httpBackend_) ->
        $scope = $rootScope.$new()
        $scope.form = jasmine.createSpy('$scope.form')
        $controller('RfiCtrl', $scope: $scope)
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
        $httpBackend.expectPOST('/api/testing').respond(201, '')
        $scope.submit('/api/testing')
        $httpBackend.flush()

      it 'should submit the form if it is valid', ->
        submitValid()

      it 'should track an event with Google Analytics', ->
        submitValid()
        expect($window.ga).toHaveBeenCalledWith(
          'send', 'event', jasmine.any(String), jasmine.any(String))

      it "should mark state as invalid when the form isn't valid", ->
        $scope.form.$valid = false
        $scope.submit('/api/testing')
        expect($scope.state.invalid).toBe(true)

      it 'should not submit or track an invalid submission', ->
        $scope.form.$valid = false
        $scope.submit('/api/testing')
        expect($window.ga).not.toHaveBeenCalled()

      it 'should prevent multiple submissions', ->
        submitValid()
        $httpBackend.resetExpectations()
        $scope.submit('/api/testing')
        $scope.submit('/api/testing')

      it 'should note a failed POST', ->
        $scope.form.$valid = true
        $httpBackend.expectPOST('/api/testing').respond(500, '')
        $scope.submit('/api/testing')
        $httpBackend.flush()
        expect($scope.state.submissionFailed).toBe(true)

  # TODO: test me!
  xdescribe 'neuRfiSelect', ->
