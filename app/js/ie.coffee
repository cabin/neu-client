angular.module('neu.ie', [])

  # XXX TODO provide localStorage shim:
  # https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Storage#Compatibility

  .directive 'oldIe', ($window) ->
    key = 'ignoredBrowserWarning'
    restrict: 'C'
    link: (scope, elm, attrs) ->
      if not $window.localStorage.getItem(key)
        elm.css(display: 'block')
      elm.bind 'click', ->
        $window.localStorage.setItem(key, true)
        elm.remove()
