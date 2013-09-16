module = angular.module('neu.directives', [])

# Return the y-offset relative to the document for the given `element`, which
# can be an angular Element or a DOM node.
elementY = (element) ->
  return 0 unless element
  # Grab the first match if this is a wrapped element.
  element = element[0] if (element.bind and element.find)
  offset = element.offsetTop
  node = element
  while node.offsetParent and node.offsetParent isnt window.document.body
    node = node.offsetParent
    continue if node.offsetTop < 0  # account for crazy scroll-wrapper
    offset += node.offsetTop
  offset





# Tween the page to the new scroll position.
scrollSmoothly = (to) ->
  TweenLite.to(window, .4, scrollTo: {y: to}, ease: Power2.easeInOut)
