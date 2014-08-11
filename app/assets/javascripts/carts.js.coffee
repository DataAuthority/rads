# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$.toggle_cart_context = (context) ->
  $(".context_"+context).show()
  $(".context_"+context+":radio").attr('checked':'checked')
  $(".cart_context").each ->
    unless $(this).attr('class').match(new RegExp(context))
      $(this).hide()
      if $(this).attr('type') == 'radio'
        $(this).removeAttr('checked')
  false

onLoad ->
  $("div#cart_context").show()
  context = $("div#cart_context").attr('class').replace(/\_selected/m, '')
  $.toggle_cart_context(context)

  $("a.switch_cart_context").click ->
    context = $(this).attr('id')
    $.toggle_cart_context(context)
    false

  $("a.remove_cart_record").click (event) ->
    link = $(this)
    $.override_remote_link link, event, () ->
        link.parent().parent().remove()

  $("a.empty_cart").click (event) ->
    link = $(this)
    $.override_remote_link link, event, () ->
        $('tr.cart_entry').remove()
