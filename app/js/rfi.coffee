angular.module('neu.rfi', [])

  .controller 'RfiCtrl', ($scope, $http, $window) ->
    $scope.state =
      invalid: false     # avoid showing errors until initial submission
      submitting: false  # avoid multiple submissions
      submitted: false   # hide the form after successful submission
      submissionFailed: false

    # As an array rather than an object to control ordering.
    $scope.types = [
      {key: 'student', value: 'Prospective student'}
      {key: 'faculty', value: 'Prospective faculty'}
      {key: 'partner-mentor', value: 'Partner/Mentor'}
      {key: 'press', value: 'Press'}
      {key: 'fan', value: 'Super fan'}
    ]
    $scope.data =
      type: $scope.types[0].key
      subscribed: true

    $scope.submit = (url) ->
      # Make sure Mobile Safari closes the keyboard.
      $window.document.activeElement.blur()
      return if $scope.state.submitting
      if $scope.form.$valid
        $scope.state.submitting = true
        postData(url)
      else
        $scope.state.invalid = true

    postData = (url) ->
      $http.post(url, $scope.data)
        .success (data, status, headers, config) ->
          $scope.state.submitted = true
          $window.ga('send', 'event', 'RFI', 'Submitted')
        .error (data, status, headers, config) ->
          $scope.state.submitting = false
          $scope.state.submissionFailed = true
          $window.ga('send', 'event', 'RFI', 'Failed submission')


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
