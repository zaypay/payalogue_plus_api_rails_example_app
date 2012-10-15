# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  ############ END JS for purchases#new ############
  
  # On orders#new, when #order_language or #order_country has been changed, an ajax-call will be made to orders_controller#new
  # It responds with new.js.erb, which in turn updates the order_payment_method select_tag with the correct language and tariff
  if($('select#language').length > 0)
    $('select#language').change ->
      $.ajax
        url: this.action
        dataType: 'script'
        data: { language: $("select#language option:selected").val(), country: $("select#country option:selected").val() }

    $('select#country').change ->
      $.ajax
        url: this.action
        dataType: 'script'
        data: { language: $("select#language option:selected").val(), country: $("select#country option:selected").val() }
  ############ END JS for purchases#new ############
  $('#alert').effect('pulsate', { times: 3}, 1500)