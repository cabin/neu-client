module = angular.module('neu.directives', [])

module.directive 'mailcheck', ->
  Kicksend.mailcheck.threshold = 2

  return {
    restrict: 'A'
    require: 'ngModel'
    scope:
      suggestedEmail: '=mailcheck'
    link: (scope, elm, attrs, ctrl) ->
      ctrl.$parsers.push (viewValue) ->
        console.log 'mailcheck', viewValue, scope.suggestedEmail
        if viewValue
          console.log 'checking', viewValue
          Kicksend.mailcheck.run
            email: encodeURI(viewValue)
            domains: ['gmail.com', 'yahoo.com', 'hotmail.com', 'googlemail.com']
            topLevelDomains: []
            suggested: (suggestion) -> scope.suggestedEmail = suggestion.full
            empty: -> scope.suggestedEmail = null
        #else
        #  scope.suggestedEmail = null
        viewValue
  }
