#= require "bootstrap/bootstrap-transition"
#= require "bootstrap/bootstrap-alert"
#= require "bootstrap/bootstrap-button"
#= require "bootstrap/bootstrap-carousel"
#= require "bootstrap/bootstrap-collapse"
#= require "bootstrap/bootstrap-dropdown"
#= require "bootstrap/bootstrap-modal"
#= require "bootstrap/bootstrap-tooltip"
#= require "bootstrap/bootstrap-popover"
#= require "bootstrap/bootstrap-scrollspy"
#= require "bootstrap/bootstrap-tab"
#= require "bootstrap/bootstrap-typeahead"
#= require "jquery-ui-1.8.19.custom.min"

$(document).ready ->
  $('#sign_out').click ->
    $('.sign-in').show()
    $('.timesheet').hide()
  $('#sign_in').click ->
    $('.sign-in').hide()
    $('.timesheet').show()

  $('#filter_date').datepicker(dateFormat: 'yy-mm-dd')
  $('#new_date').datepicker(dateFormat: 'yy-mm-dd')
