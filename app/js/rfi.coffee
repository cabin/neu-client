angular.module('neu.rfi', [])

  .controller 'RfiCtrl', ($scope, $http) ->
    $scope.state =
      invalid: false     # avoid showing errors until initial submission
      submitting: false  # avoid multiple submissions
      submitted: false   # hide the form after successful submission
      submissionFailed: false

    # As an array rather than an object to control ordering.
    $scope.types = [
      {key: 'student', value: 'Prospective student'}
      {key: 'faculty', value: 'Prospective faculty'}
      {key: 'partner', value: 'Prospective partner'}
      {key: 'fan', value: 'Super fan'}
    ]
    $scope.data =
      type: $scope.types[0].key
      subscribe: true

    $scope.submit = ->
      return if $scope.state.submitting
      if $scope.form.$valid
        $scope.state.submitting = true
        postData()
      else
        $scope.state.invalid = true

    postData = ->
      # TODO
      $http.post('/api/...', $scope.data)
        .success (data, status, headers, config) ->
          $scope.state.submitted = true
          alert('Submission successful')
        .error (data, status, headers, config) ->
          $scope.state.submitting = false
          $scope.state.submissionFailed = true
          alert("Submission failed (probably because there's no API server...)")
