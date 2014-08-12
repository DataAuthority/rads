# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$.toggle_cart_context = (context) ->
  $(".cart_context").each ->
    unless $(this).attr('class').match(new RegExp(context))
      $(this).find("input:radio:first").removeAttr('checked')
      $(this).find("input:radio:first").prop('checked':false)
      $(this).hide()
  $(".context_"+context).find("input:radio:first").attr('checked':'checked')
  $(".context_"+context).find("input:radio:first").prop('checked':'checked')
  $(".context_"+context).show()
  false

onLoad ->
  $("div#cart_context").each ->
    $(this).show()
    context = $(this).attr('class').replace(/\_selected/m, '')
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
