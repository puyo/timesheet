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
#= require "jquery-ui-1.8.21.custom.min"
#= require "unique"
#= require "sort-elements"

class Timesheet
  @jobCodeIndex: {}
  @projectsIndex: {}
  @peopleIndex: {}
  @projects: []

  @jobCodes = [
    {label: '01A - Accounts General', value: '01A'},
    {label: '01B - Accounts Payable', value: '01B'},
    {label: '01C - Accounts Receivable', value: '01C'},
    {label: '01D - Accounts Budgeting/Cashflow/Job Analysis', value: '01D'},

    {label: '02A - Lunch', value:'02A'},
    {label: '02B - Personal Time', value:'02B'},

    {label: '03A - General Admin', value: '03A'},
    {label: '03B - Non-Paid Client Admin', value: '03B'},
    {label: '03B-2 - Paid Client Admin', value: '03B-2'},
    {label: '03C - Client Quoting', value: '03C'},
    {label: '03D - Client Meetings', value: '03D'},
    {label: '03E - Supplier/Contractor Briefs', value: '03E'},
    {label: '03F - Production Meetings/Schedules', value: '03F'},
    {label: '03G - Protein Marketing', value: '03G'},
    {label: '03H - Protein Training', value: '03H'},

    {label: '04A - Print', value: '04A'},
    {label: '04A-2 - Print Amends', value: '04A-2'},
    {label: '04B - Web', value: '04B'},
    {label: '04B-2 - Web Amends', value: '04B-2'},
    {label: '04C - Interactive', value: '04C'},
    {label: '04C-2 - Interactive Amends', value: '04C-2'},
    {label: '04D - Retouching', value: '04D'},
    {label: '04D-2 - Retouching Amends', value: '04D-2'},
    {label: '04F - Brand', value: '04F'},
    {label: '04F-2 - Brand Amends', value: '04F-2'},
    {label: '04G - Pitch Work', value: '04G'},
    {label: '04H - Creative Work', value: '04H'},
    {label: '04PP - Pitch Perfect', value: '04PP'},
    {label: '04PP-2 - Pitch Perfect Amends', value: '04PP-2'},
    {label: '04i - App', value: '04i'},
    {label: '04i-2 - App Amends', value: '04i-2'},

    {label: '05A - Film Meetings', value: '05A'},
    {label: '05B - Film Writing', value: '05B'},
    {label: '05C - Film Admin', value: '05C'},
  ]

  @addJobCode: (projectId, todoItemId, jobCode) ->
    @jobCodeIndex[projectId + '-' + todoItemId] = jobCode
    @updateEntriesWithJobCode(projectId, todoItemId, jobCode)

  @loadJobCodes: ->
    tuples = $('[data-todo-item-id][data-project-id]').map ->
      $el = $(@)
      $el.data('project-id') + '-' + $el.data('todo-item-id')
    for tuple in $.unique(tuples)
      vals = tuple.split('-')
      projectId = vals[0]
      todoItemId = vals[1]
      @loadJobCode(projectId, todoItemId)

  @loadJobCode: (projectId, todoItemId) ->
    url = '/projects/' + projectId + '/todo_items/' + todoItemId + '.json'
    $.ajax(
      url: url
    ).done (data) =>
      jobCode = data.todo_item.content
      @addJobCode(projectId, todoItemId, jobCode)

  @loadProjectNames: ->
    projectIds = $.unique($.map($('[data-project-id]'), (el) -> $(el).data('project-id')))
    for projectId in projectIds
      project = @projectsIndex[projectId]
      if project
        @updateEntriesWithProjectName(projectId, project.name)

  @updateEntriesWithJobCode: (projectId, todoItemId, jobCode) ->
    selector = '[data-todo-item-id="' + todoItemId + '"][data-project-id="' + projectId + '"]'
    $('.job_code' + selector).text(jobCode)
    $('input' + selector).val(jobCode)

  @updateEntriesWithProjectName: (projectId, projectName) ->
    selector = '[data-project-id="' + projectId + '"]'
    $('.project' + selector).text(projectName)

  @addEntry: (id, html) ->
    $('.timesheet table.table').append(html)
    @refreshEntry(id)

  @updateEntry: (id, html) ->
    $view = @timeEntryView(id)
    $parent = $view.parent()
    index = $parent.children().index($view)
    $edit = @timeEntryEdit(id)
    $view.remove()
    $edit.remove()
    $parent.find('tr').eq(index).before(html)
    @refreshEntry(id)

  @refreshEntry: (id) ->
    $view = @timeEntryView(id)
    projectId = $view.data('project-id')
    todoItemId = $view.data('todo-item-id')
    key = projectId + '-' + todoItemId
    jobCode = @jobCodeIndex[key]
    if jobCode
      @updateEntriesWithJobCode(projectId, todoItemId, jobCode)
    else
      @loadJobCode(projectId, todoItemId)
    project = @projectsIndex[projectId]
    if project
      @updateEntriesWithProjectName(projectId, project.name)
    @resort()
    @updateEntriesWithProjects()
    @updateEntriesWithPeople()

  @removeEntry: (id) ->
    $view = @timeEntryView(id)
    $view.fadeOut "normal", =>
      $view.remove()
      @resort()
    @timeEntryEdit(id).remove()

  @sortKey: ($el, n) ->
    result = $el.data('date') + '_' + $el.data('time-entry-id')
    if $el.hasClass('edit_time_entry')
      result += '_2'
    else
      result += '_1'
    return result

  @resort: ->
    $('.totals').remove()
    $entries = $('tr.time_entry, tr.edit_time_entry')
    $entries.tsort sortFunction: (a, b) =>
      x = @sortKey(a.e, a.n)
      y = @sortKey(b.e, b.n)
      if x == y 
        0
      else if x > y
        1
      else
        -1

    dates = $entries.map ->
      $(@).data('date')
    dates = $.unique(dates)
    for date in dates
      dateObj = new Date(date)
      formattedDate = date #$.datepicker.formatDate('yy-mm-dd&nbsp;&nbsp;&nbsp;DD', dateObj)
      day = $.datepicker.formatDate('DD', dateObj)
      entries = $('.time_entry[data-date="' + date + '"]')
      sum = 0.0
      for entry in entries
        sum += Number($(entry).find('.hours').text())
      html = '<tr class="totals"><td colspan="1">' + formattedDate + '</td><td colspan="3"> ' + day + '</td><td colspan="3">' + sum + '</td></tr>'
      $('.edit_time_entry[data-date="' + date + '"]').last().after(html)

  @disableCreate: ->
    # TODO: still allows hitting enter...
    #$('#new_time_entry').find('input[type=submit]').attr('disabled', 'disabled')

  @enableCreate: ->
    #$('#new_time_entry').find('input[type=submit]').attr('disabled', null)
    $('#time_entry_job_code').focus()

  @updateEntriesWithProjects: () ->
    for e in $('.field.project_id select[data-project-id]')
      $select = $(e)
      selectedId = Number($select.data('project-id'))
      for project in @projects
        $select.data('project-id', null).append($('<option>', value: project.id, selected: project.id == selectedId).text(project.name))

  @updateEntriesWithPeople: () ->
    for e in $('.field.person_id select[data-person-id]')
      $select = $(e)
      selectedId = Number($select.data('person-id'))
      for person in @people
        $select.data('person-id', null).append($('<option>', value: person.id, selected: person.id == selectedId).text(person.name))

  @showTimeEntryEdit: (id) ->
    @timeEntryEdit(id).show()
    @timeEntryView(id).hide()

  @hideTimeEntryEdit: (id) ->
    @timeEntryEdit(id).show()
    @timeEntryView(id).hide()
    $view = @timeEntryView(id)
    $edit = @timeEntryEdit(id)
    $view.show()
    $edit.hide()

  @timeEntryView: (id) ->
    $('#time_entry_' + id)

  @timeEntryEdit: (id) ->
    $('#edit_time_entry_' + id)

window.Timesheet = Timesheet

$ ->
  Timesheet.loadJobCodes()
  Timesheet.loadProjectNames()
  Timesheet.resort()
  Timesheet.updateEntriesWithProjects()
  Timesheet.updateEntriesWithPeople()

  $('#sign_out').click ->
    $('.sign-in').show()
    $('.timesheet').hide()

  $('#sign_in').click ->
    $('.sign-in').hide()
    $('.timesheet').show()

  $('body').on 'click', '.time_entry_edit', (e) ->
    e.preventDefault()
    id = $(e.target).data('time-entry-id')
    Timesheet.showTimeEntryEdit(id)

  $('body').on 'click', '.time_entry_cancel', (e) ->
    e.preventDefault()
    id = $(e.target).closest('[data-time-entry-id]').data('time-entry-id')
    Timesheet.hideTimeEntryEdit(id)

  $('body').on 'focus', 'input[name="time_entry[job_code]"]', ->
    $(this).autocomplete(source: Timesheet.jobCodes)

  $.datepicker.setDefaults(dateFormat: 'yy-mm-dd')

  $('input.filter.date').datepicker()

  $('body').on 'focus', 'input[name="time_entry[date]"]', ->
    $(this).datepicker().datepicker('show')
    true

  $('#new_time_entry').submit ->
    Timesheet.disableCreate()
