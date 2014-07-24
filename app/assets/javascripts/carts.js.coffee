# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
onLoad ->
  $("a.remove_cart_record").click (event) ->
    link = $(this)
    $.rails.stopEverything(event)
    $.ajax
      type: "DELETE",
      url: link.attr('href'),
      dataType: "json",
      complete: () ->
        link.parent().parent().remove()
    event.preventDefault()
    false

  $("a.empty_cart").click (event) ->
    link = $(this)
    $.rails.stopEverything(event)
    $.ajax
      type: "DELETE",
      url: link.attr('href'),
      dataType: "json",
      complete: () ->
        $('tr.cart_entry').remove()
    event.preventDefault()
    false
