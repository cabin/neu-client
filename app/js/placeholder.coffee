angular.module('neu.placeholder', [])

  # Based on Prototype's implementation; get the `id` of the given `element`,
  # generating one first if necessary.
  .factory 'identify', ->
    idCounter = 1
    (element) ->
      id = element.attr('id')
      return id if id
      id = 'placeholder-id-' + idCounter++
      while document.getElementById(id)
        id = 'placeholder-id-' + idCounter++
      element.attr('id', id)
      return id

  # Provide a cross-browser HTML5 `placeholder` attribute implementation.
  .directive 'placeholder', (identify, $timeout) ->
    restrict: 'A'
    link: (scope, elm, attrs) ->
      return if Modernizr?.placeholder
      container = null
      createElements = ->
        container = angular.element(document.createElement('div'))
        label = angular.element(document.createElement('label'))
        label.text(attrs.placeholder)
        elm.attr('placeholder', '')
        label.attr('for', identify(elm))
        # Update the DOM.
        elm.after(container)
        container.append(label)
        container.append(elm)
        container.addClass('placeholder')

      togglePlaceholder = ->
        showPlaceholder = elm.val() is ''
        container.toggleClass('is-visible', showPlaceholder)

      createElements()
      elm.bind('change keydown cut paste', -> $timeout(togglePlaceholder, 0))
      togglePlaceholder()
