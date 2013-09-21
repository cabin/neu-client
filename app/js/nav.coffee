angular.module('neu.nav', [])

  .directive 'neuMobileNav', ->
    trim = (str) -> str.replace(/^\s\s*/, '').replace(/\s\s*$/, '')
    restrict: 'A'
    controller: ($scope) ->
      $scope.$watch 'viewport.width', (width) ->
        $scope.isMobile = width < 768
        $scope.menuOpen = not $scope.isMobile
      $scope.toggleMenu = ->
        $scope.menuOpen = not $scope.menuOpen
    link: (scole, elm, attrs) ->
      ul = elm.children().eq(1)
      current = null
      links = []
      angular.forEach ul.children(), (li) ->
        li = angular.element(li)
        if li.hasClass('is-selected')
          current = trim(li.text())
        a = li.children().eq(0)
        [text, url] = [trim(a.text()), a.attr('href')]
        text = text.replace(/^Beta\s+/i, '')
        links.push([text, url])
