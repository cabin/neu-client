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
      {key: 'press', value: 'Press'}
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
          console.log('Submission successful')
        .error (data, status, headers, config) ->
          $scope.state.submitting = false
          $scope.state.submissionFailed = true
          console.log("Submission failed (probably because there's no API server...)")


  .directive 'neuRfiSelect', ($timeout) ->
    restrict: 'A'
    require: '^select'
    link: (scope, elm, attrs) ->
      wrapper = angular.element('<div class="custom-select"></div>')
      indicator = angular.element('<a class="custom-select__indicator"></a>')
      container = angular.element('<div class="custom-select__container"></div>')
      wrapper.append(indicator)
      wrapper.append(container)

      closeMenu = -> wrapper.removeClass('is-open')
      angular.element(document).bind('click', closeMenu)

      # Track changes to the backing `select`.
      elm.bind 'change', ->
        newVal = elm.val()
        for opt in container.children()
          opt = angular.element(opt)
          opt.toggleClass('is-selected', opt.data('value') is newVal)

      # Open and close the popup menu; send selections to the backing `select`.
      wrapper.bind 'click', (event) ->
        event.stopPropagation()
        if wrapper.hasClass('is-open')
          opt = angular.element(event.target)
          elm.val(opt.data('value'))
          elm.triggerHandler('change')
        wrapper.toggleClass('is-open')

      # Give the select directive time to create its options, then mirror them.
      $timeout ->
        for option in elm.children()
          option = angular.element(option)
          opt = angular.element('<a class="custom-select__option"></a>')
          opt.text(option.text())
          opt.data('value', option.val())
          opt.toggleClass('is-selected', elm.val() is option.val())
          container.append(opt)
        elm.after(wrapper)
        elm.css(display: 'none')
