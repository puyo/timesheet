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

$ ->
  $('#sign_out').click ->
    $('.sign-in').show()
    $('.timesheet').hide()
  $('#sign_in').click ->
    $('.sign-in').hide()
    $('.timesheet').show()

  projectUrls = $.map($('[data-project-url]'), (val, i) ->
    $(val).data('project-url')
  )
  projectUrls = $.unique(projectUrls)
  $.each(projectUrls, (i, url) ->
    $.ajax(
      url: url
    ).done (data) ->
      $('[data-project-url="' + url + '"]').text(data.project.name)
  )

  todoItemUrls = $.map($('[data-todo-item-url]'), (val, i) ->
    $(val).data('todo-item-url')
  )
  todoItemUrls = $.unique(todoItemUrls)
  $.each(todoItemUrls, (i, url) ->
    $.ajax(
      url: url
    ).done (data) ->
      $('[data-todo-item-url="' + url + '"]').text(data.todo_item.content)
  )
