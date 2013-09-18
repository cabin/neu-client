angular.module('neu.ie', [])

  # Support for IE < 8.
  # https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Storage#Compatibility
  .run ($window) ->
    if not $window.localStorage
      $window.localStorage =
        getItem: (sKey) ->
          return null if not sKey or not @hasOwnProperty(sKey)
          unescape(document.cookie.replace(new RegExp("(?:^|.*;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*"), "$1"))

        key: (nKeyId) ->
          unescape(document.cookie.replace(/\s*\=(?:.(?!;))*$/, "").split(/\s*\=(?:[^;](?!;))*[^;]?;\s*/)[nKeyId])

        setItem: (sKey, sValue) ->
          return  unless sKey
          document.cookie = escape(sKey) + "=" + escape(sValue) + "; expires=Tue, 19 Jan 2038 03:14:07 GMT; path=/"
          @length = document.cookie.match(/\=/g).length

        length: 0
        removeItem: (sKey) ->
          return  if not sKey or not @hasOwnProperty(sKey)
          document.cookie = escape(sKey) + "=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/"
          @length--

        hasOwnProperty: (sKey) ->
          (new RegExp("(?:^|;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test(document.cookie)

      $window.localStorage.length = (document.cookie.match(/\=/g) or $window.localStorage).length

  .directive 'oldIe', ($window) ->
    key = 'ignoredBrowserWarning'
    restrict: 'C'
    controller: ($scope, $element) ->
      $scope.ignore = ->
        $window.localStorage.setItem(key, true)
        $element.remove()
    link: (scope, elm, attrs) ->
      if not $window.localStorage.getItem(key)
        elm.css(display: 'block')
