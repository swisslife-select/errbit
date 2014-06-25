// App JS

$(function() {
  function init() {
    disableScrollToBottom();

    activateTabbedPanels();

    activateSelectableRows();

    toggleProblemsCheckboxes();

    bindRequiredPasswordMarks();

    // On page apps/:app_id/edit
    $('a.copy_config').on("click", function() {
      $('select.choose_other_app').show().focus();
    });

    $('select.choose_other_app').on("change", function() {
      var loc = window.location;
      window.location.href = loc.protocol + "//" + loc.host + loc.pathname +
                             "?copy_attributes_from=" + $(this).val();
    });

    $('input[type=submit][data-action]').live('click', function() {
      $(this).closest('form').attr('action', $(this).attr('data-action'));
    });
  }

  function disableScrollToBottom(){
    if (location.hash) {
      window.scrollTo(0, 0);
    }
  }

  function currentTabName(){
    return window.location.hash.slice(1) || 'summary'
  }

  function activateTabbedPanels() {
    $('.tab-bar a').each(function(){
      var tab = $(this);
      var panel = $('#'+tab.attr('rel'));
      panel.addClass('panel');
      panel.find('h3').hide();
    });

    $('.tab-bar a').click(function(){
      activateTab($(this));
      return(false);
    });
    var currentTab = currentTabName();
    activateTab($('.tab-bar ul li a.button[rel=' + currentTab + ']'));
  }

  function activateTab(tab) {
    var rel = tab.attr('rel');
    history.pushState(null, null, '#' + rel);
    tab = $(tab);
    var panel = $('#'+rel);

    tab.closest('.tab-bar').find('a.active').removeClass('active');
    tab.addClass('active');

    // If clicking into 'backtrace' tab, hide external backtrace
    if (rel == "backtrace") { hide_external_backtrace(); }

    setAnchorForPaginationLinks();

    $('.panel').hide();
    panel.show();
  }

  function setAnchorForPaginationLinks(){
    var links = $('.notice-pagination a');
    links.each(function(){
      var link = $(this);
      var new_href = link.attr('href').replace(/#.*/, '') + '#' + currentTabName();
      link.attr('href', new_href);
    });
  }

  window.toggleProblemsCheckboxes = function() {
    var checkboxToggler = $('#toggle_problems_checkboxes');

    checkboxToggler.on("click", function() {
      $('input[name^="problems"]').each(function() {
        this.checked = checkboxToggler.get(0).checked;
      });
    });
  }

  function activateSelectableRows() {
    $('.selectable tr').click(function(event) {
      if(!_.include(['A', 'INPUT', 'BUTTON', 'TEXTAREA'], event.target.nodeName)) {
        var checkbox = $(this).find('input[name="problems[]"]');
        checkbox.attr('checked', !checkbox.is(':checked'));
      }
    });
  }

  function bindRequiredPasswordMarks() {
    $('#user_github_login').keyup(function(event) {
      toggleRequiredPasswordMarks(this)
    });
  }

  function toggleRequiredPasswordMarks(input) {
      if($(input).val() == "") {
        $('#user_password').parent().attr('class', 'required')
        $('#user_password_confirmation').parent().attr('class', 'required')
      } else {
        $('#user_password').parent().attr('class', '')
        $('#user_password_confirmation').parent().attr('class', '')
      }
  }

  toggleRequiredPasswordMarks();

  function hide_external_backtrace() {
    $('tr.toggle_external_backtrace').hide();
    $('td.backtrace_separator').show();
  }
  function show_external_backtrace() {
    $('tr.toggle_external_backtrace').show();
    $('td.backtrace_separator').hide();
  }
  // Show external backtrace lines when clicking separator
  $('td.backtrace_separator span').on('click', show_external_backtrace);
  // Hide external backtrace on page load
  hide_external_backtrace();

  $('.head a.show_tail').click(function(e) {
    $(this).hide().closest('.head_and_tail').find('.tail').show();
    e.preventDefault();
  });

  init();
});
