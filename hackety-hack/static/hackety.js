function hacketyPrompt(str) {
  str = prompt(str);
  if (!str) return '';
  return str;
}

/* tutor */
function tutor_close() {
  $.ajax({
    url: '/learnclose',
    complete: function(r) {
      $("#tutor").hide('fast');
    }
  });
}

function tutor_goto(num) {
  if (num < 0) return;
  if (num >= tutor_lesson_end) return;
  $.ajax({
    url: '/tutor/' + num,
    complete: function(r) {
      tutor_lesson = num;
      $("#tutor .lesson").html(r.responseText);
    }
  });
}

function tutor_index() {
  $.ajax({
    url: '/tutor/index',
    complete: function(r) {
      $("#tutor .lesson").html(r.responseText);
    }
  });
}

function tutor_back() {
  tutor_goto(tutor_lesson - 1);
}

function tutor_next() {
  tutor_goto(tutor_lesson + 1);
}

/* help */
function open_tocsub(name) {
  $('ul.tocsub').hide('fast');
  $('ul.' + name).show('fast');
  open_helpsect(name)
}

function open_helpsect(name) {
  $('div.helpsect').hide();
  $('div.' + name).show();
  document.documentElement.scrollTop = 0;
}

/* about page */
function about_hackety_hack() {
  $("#about_hackety_hack").show();
}

function close_about_hackety_hack() {
  $("#about_hackety_hack").hide();
}

function popup_hackety_hack() {
  $("#popup_hackety_hack").show();
  $('#popup').html("<div id='stdout' class='webpage'>" + stdhtml + "</div>");
}

function is_popup_hackety_hack_showing() {
  return ($("#popup_hackety_hack").attr('style').toString() == 'display: block;' ? true : false);
}

function popup_hackety_form() {
  var inputs = {};
  $("#popup input, #popup textarea, #popup select").each(function(){
    if (this.type != 'button') {
      inputs[this.name] = $(this).val();
    }
  });
  return inputs;
}

function import_hackety_programs(files) {
  for (var name in files) {
    if (confirm("Import " + name + ".rb?"))
    {
      $.ajax({
        url: '/new/' + encodeURIComponent(name),
        data: {script: files[name]},
        complete: function(r) {
          if (r.responseText == 'FAILED')
            alert("You already have a program named " + name + ".");
          else
            window.location = '/start';
        }
      });
    }
  }
}

function pressed_popup_hackety_hack() {
  $("#popup_hackety_hack").get(0).pressed = this.value;
}

function event_popup_hackety_hack() {
  var p = $("#popup_hackety_hack").get(0);
  var b = p.pressed;
  p.pressed = null;
  return b;
}

function save_popup_hackety_hack() {
  $("#popup_hackety_hack").hide();
}

function close_popup_hackety_hack() {
  $('#popup').html('');
  $("#popup_hackety_hack").hide();
}

/* script editor */
function cancel_hackety_script() {
  close_popup_hackety_hack();
  $.get('/eval/cancel');
}

var stdhtml = '<div id="waiting"><div id="waitingInfo">Running...</div><div class="spinner"><img src="/static/waiting.gif" /></div></div><div class="cancelButton"><input type="button" name="cancelProgram" value="Stop the program" onClick="cancel_hackety_script()" /></div>';

function run_hackety_code() {
  popup_hackety_hack();
  $.get('/eval',  {cmd: script.getCode()});
}

function run_hackety_script(name) {
  popup_hackety_hack();
  $.get('/run/' + name);
}

function share_hackety_script(name) {
  popup_hackety_hack();
  $.get('/share/' + name);
}

function share_hackety_table(name) {
  popup_hackety_hack();
  $.get('/table-share/' + name);
}

function save_hackety_script(name, msg) {
  saved = 'save';
  if (name == 'New')
  {
    saved = 'new';
    if (typeof(msg) == 'undefined')
      msg = '';
    name = hacketyPrompt(msg + "Enter a name for your new program:");
    if (!name) return;
  }
  
  // Convert the page to an edit page.
  $('h1').text(name);
  $("input#save").attr("onclick", "save_hackety_script('" + name + "')");
  $('input#copy').show();
  
  // Pass the program to Ruby to save.
  $.ajax({
    url: '/' + saved + '/' + encodeURIComponent(name),
    data: {script: script.getCode()},
    complete: function(r) {
      if (r.responseText == 'FAILED')
      {
        save_hackety_script('New', "You already have a program named " + name + ".\n");
      }
      else
      {
        popup_hackety_hack();
        $('#stdout').html(r.responseText);
      }
    }
  });
}

function save_preferences()
{
  var prefs = {};
  $("input[@type='text'], input[@type='password']").each(function(){
    prefs[this.name] = this.value;
  });
  $.ajax({
    url: '/prefsave', data: prefs,
    complete: function(r) {
      $("#prefs").html("<h1>Your Setup</h1><p>Your preferences have been saved.</p>");
    }
  });
}

function rollon(obj, name)
{
  obj.src = "/static/menu-" + name + "-on.png";
}

function rolloff(obj, name)
{
  obj.src = "/static/menu-" + name + "-off.png";
}

$(document).ready(function(){
  $("img.appicon").mouseover(function() {
    $("div.actions").hide();
    $("../../div.actions", this).show();
  });
  $("div.actions > *").mouseover(function() {
    $("..", this).show();
  });
  $("div.actions").mouseout(function() {
    $(this).hide();
  });
});
