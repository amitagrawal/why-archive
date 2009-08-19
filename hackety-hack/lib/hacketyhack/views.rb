module Camping::Views
  CONFIRM = %{if(!this.title||confirm(this.title+'?')){window.location = this.href}return false;}

  def rollover name
    li { a(:href => "/#{name}") { img :src => "/static/menu-#{name}-off.png", 
      :onmouseout => "rolloff(this, '#{name}')", :onmouseover => "rollon(this, '#{name}')" } }
  end

  def start
    div.options! do
      text "version #{HacketyHack::VERSION} | "
      a "Your Setup", :href => "hack://hackety/prefs"
    end
    div.mainmenu! do
      ul do
        rollover "new"
        rollover "learn"
        rollover "help"
      end
    end
    if @apps.empty?
      div.no_apps! do
        h1 "Welcome to Hackety Hack!"
        p "You haven't got any shared programs yet.  Let's remedy that."
        ul do
          li { a "Take the seven lessons.", :href => R(Learn) }
          li { text "or, Visit the "; a "Shared Programs", :href => "http://central.hacketyhack.net/"; text " area." }
          li { text "or, if you're a pro, "; a "Start", :href => "/new"; text " a new program." }
        end
      end
    else
      h3 { img :src => "/static/menu-saved.png" }
      div.apps! do
        ul do
          @apps.each do |app|
            li { 
              div.actions {
                img :src => "/static/hackety-progdrop-icon.png"
                ul {
                  li { strong { a "Run this.", :href => "javascript:;", :onclick => "run_hackety_script('#{app[:name]}')" } }
                  li { a "Share this.", :href => "javascript:;", :onclick => "share_hackety_script('#{app[:name]}')" }
                  li { a "Delete this!", :href => R(Delete, app[:name]), :onclick => CONFIRM,
                    :title => "Delete the program '#{app[:name]}'" }
                }
              }
              h4 { img.appicon :src => "/static/icon-program.png"
                a app[:name], :href => R(Edit, app[:name]) }
              p app[:desc] if app[:desc]
            }
          end
        end
      end
    end
    unless @tables.empty?
      h3.db! { img :src => "/static/menu-tables.png" }
      div.tables! do
        ul do
          @tables.each do |table|
            li { 
              div.actions {
                img :src => "/static/hackety-tabledrop-icon.png"
                ul {
                  li { a "Share this.", :href => "javascript:;", :onclick => "share_hackety_table('#{table}')" }
                  li { a "Delete this!", :href => R(TableDelete, table), :onclick => CONFIRM,
                    :title => "Delete the '#{table}' table" }
                }
              }
              icon = HacketyHack.check_share(table, 'Table') ? "icon-table-shared" : "icon-table"
              h4 { img.appicon(:src => "/static/#{icon}.png"); puts " #{table}" } 
            }
          end
        end
      end
    end
    if @input['files']
      import = [*@input['files']].inject({}) do |hsh, fname|
        begin
          hsh[File.basename(fname.gsub(/\.hack-rb$/, ''))] = File.open(fname, 'rb') { |f| f.read }
        rescue
        end
        hsh
      end
      self << <<-END
        <script language="Javascript">
          $(document).ready(function(){
            import_hackety_programs(#{import.to_json})
          });
        </script>
      END
    end
  end
  
  def prefs
    h1 "Your Setup"
    form do
      fieldset do
        legend "HacketyHack.net Login"
        div.optional do
          label "Username", :for => "hh_username"
          input :type => "text", :name => "hh_username", :value => HacketyHack::PREFS["hh_username"]
        end
        div.optional do
          label "Password", :for => "hh_pass"
          input :type => "password", :name => "hh_pass", :value => HacketyHack::PREFS["hh_pass"]
        end
      end
      fieldset do
        legend "HTTP Proxy"
        div.optional do
          label "URL (example: http://my.proxy.net:8080/)", :for => "hh_proxy"
          input :type => "text", :name => "hh_proxy", :value => HacketyHack::PREFS["hh_proxy"]
        end
      end
      input :type => "button", :value => "Cancel", :name => "cancel", :onclick => "window.location = '/'"
      input.save! :type => "button", :value => "Save", :onclick => "save_preferences()"
    end
  end

  def edit
    script :type => "text/javascript", :src => "/static/codepress/codepress.js"

    h1 @app[:name]
    if @app[:name] == "New"
      h2 "A blank program, started on #{Time.now.calendar_with_time}."
    else
      h2 "This program was last saved on #{@app[:mtime].calendar_with_time}."
    end
    show_copy = @app[:name] == 'New' ? 'display:none' : ''
    div.input! do
      form :method => 'GET' do
        textarea.script!.codepress.ruby(@app[:script] || "", :style => "width:100%;height:300px", :wrap => "off")
        input.run! :type => 'button', :value => 'Run',
          :onclick => "run_hackety_code()"
        input.save! :type => 'button', :value => 'Save',
          :onclick => "save_hackety_script('#{@app[:name]}')"
        input.copy! :type => 'button', :value => 'Copy',
          :onclick => "save_hackety_script('New')",
          :style => show_copy
        div.banner "Program will run below."
      end
    end
  end
  
  def console
    eval %q{poem = "My toast has flown from my hand\nAnd my toast has gone to the moon.\nBut when I saw it on television,\nPlanting our flag on Halley's comet,\nMore still did I want to eat it.\n"}, TOPLEVEL_BINDING
    xhtml_transitional do
      head do
        title "Try Ruby!"
        script :type => "text/javascript", :src => "/static/jquery.js"
        script :type => "text/javascript", :src => "/static/console/mouseapp_2.js"
        script :type => "text/javascript", :src => "/static/console/mouseirb_2.js"
        script :type => "text/javascript", :src => "/static/console/irb.js"
        script :type => "text/javascript", :src => "/static/hackety.js"
        link :rel => "stylesheet", :type => "text/css", :href => "/static/site.css"
      end
      body.console! do
        corners
        div.wrapper! do
          div.container! do
            self << <<-END
              <div id="content">
                  <div id="lilBrowser">
                      <div id="lbTitlebar">
                          <h3 id="lbTitle">A Popup Browser</h3>
                          <p id="lbClose">[<a href="javascript:void(window.irb.options.popup_close());">x</a>]</p>
                      </div>
                      <iframe width="500" height="400" src="/" id="lbIframe"></iframe>
                  </div>
                  <div id="shellwin">
                  <div id="terminal">
                      <div id="irb"></div>
                  </div>
                  </div>
                  <div id="waitingInfo"></div>
                  <div id="helpstone">
                      <div class="stretcher chapmark">
                          <p>Try out Ruby code in the prompt above.  In addition
                             to Ruby's builtin methods, the following commands are available:</p>
                          <ul class="commands">
                             <li><strong>help</strong>
                                 Start the 15 minute interactive tutorial.  Trust me, it's very basic!</li>
                             <li><strong>help 2</strong>
          
                                 Hop to chapter two.</li>
                             <li><strong>clear</strong>
                                 Clear screen.  Useful if your browser starts slowing down.
                                 Your command history will be remembered.</dd>
                             <li><strong>back</strong>
                                 Go back one screen in the tutorial.</li>
                             <li><strong>reset</strong>
          
                                 Reset the interpreter if you get too deep. (or <b>Ctrl-D</b>!)</li>
                             <li><strong>time</strong>
                                 A stopwatch.  Prints the time your session has been open.</li>
                          </ul>
                          <div class="answer"></div>
                      </div>
                      <div class="note">Trapped in double dots?  A quote or something was left open.  Type: <strong>reset</strong> or hit <strong>Ctrl-D</strong>.</div>
                  </div>
              </div>
              <input class="keyboard-selector-input" type="text" id="irb_input" autocomplete="off" />
            END
          end
        end
        hidden_popups
      end
    end
  end
  
  def corners
    div.leftside! ''
    div.rightside! ''
    div.topside! ''
    div.corner1! { img :src => "/static/menu-corner1.png" }
    div.corner2! { img :src => "/static/menu-corner2.png" }
  end

  def show(body)
    html =
    xhtml_transitional do
      head do
        title @title
        script :type => "text/javascript", :src => "/static/jquery.js"
        script :type => "text/javascript", :src => "/static/ifx.js"
        script :type => "text/javascript", :src => "/static/iutil.js"
        script :type => "text/javascript", :src => "/static/ifxslide.js"
        script :type => "text/javascript", :src => "/static/ifxbounce.js"
        script :type => "text/javascript", :src => "/static/json.js"
        script :type => "text/javascript", :src => "/static/hackety.js"
        link :rel => "stylesheet", :type => "text/css", :href => "/static/site.css"
        link :rel => "stylesheet", :type => "text/css", :href => "/static/lightbox.css"
      end
      body do
        corners
        div.wrapper! do
          if HacketyHack.tutor_on?
            HacketyHack.tutor_page = @env.REQUEST_PATH
            script "var tutor_lesson = #{HacketyHack.tutor_lesson}; var tutor_lesson_end = #{HacketyHack::TUTOR.length}", :type => "text/javascript"
            div.tutor! do
              div.controls do
                span "Controls "
                a(:href => "javascript:;", :onclick => "tutor_back()") { img :src => "/static/icon-tutor-back.png" }
                a(:href => "javascript:;", :onclick => "tutor_close()") { img :src => "/static/icon-tutor-stop.png" }
                a(:href => "javascript:;", :onclick => "tutor_next()") { img :src => "/static/icon-tutor-fwd.png" }
                span " | "
                a("Skip Around", :href => "javascript:;", :onclick => "tutor_index()")
              end
              div.page do
                div.lesson do
                  self << HacketyHack.get_tutor_html(HacketyHack.tutor_lesson)
                end
              end
            end
          end
          div.header! { a(:href => R(Start)) { img :src => "/static/hackety-insignia.png" } }
          div.container! { div(:id => body) { __send__(body) } }
        end
        hidden_popups
      end
    end
  end

  def hidden_popups
    div.popup_hackety_hack! do
      div.overlay {}
      div.popup_wrapper! do
        div.toppp { a(:href => "javascript:;", :onclick => "close_popup_hackety_hack()") {
          img.popup_close! :src => '/static/hackety-popup-topright.png' } }
        div.leftpp { div.rightpp { div.popup! {} } }
        div.bottompp { img :src => '/static/hackety-popup-bottomright.png' }
      end
    end
    div.about_hackety_hack! :onclick => 'close_about_hackety_hack()' do
      div.overlay {}
      div.box { img :src => '/static/hackety-about.png' }
    end
  end
  
  def tutor_index
    h4 "Want to Skip Around?"
    h1 "The Lesson List"
    p "Click on the name of a lesson and the tutor will jump to the first page of that lesson.  Or click Return to go
       back to the lesson you were at."
    ol do
      HacketyHack::TUTOR_INDEX.each do |i, k|
        li { a k, :href => "javascript:;", :onclick => "tutor_goto(#{i})" }
      end
    end
    div.nextpage { a(:href => "javascript:;", :onclick => "tutor_goto(tutor_lesson)") { self << "&rarr; Return" } } 
  end

  def help(helplink)
   xhtml_transitional do
      head do
        title 'Hackety Help'
        link :rel => "stylesheet", :type => "text/css", :href => "/static/site.css"
        script :type => "text/javascript", :src => "/static/jquery.js"
        script :type => "text/javascript", :src => "/static/hackety.js"
      end
      body.helppage! do
        corners
        div.wrapper! do
          div.toc! do
            ul do
              HacketyHack::DOCS.each do |sect_s, sect_h|
                li do
                  sect_cls = sect_h['class']
                  h4 { a sect_s, :href => "javascript:;", :onclick => "open_tocsub('#{sect_cls}')" }
                  ul :class => "#{sect_cls} tocsub" do
                    sect_h['sections'].each do |meth_s, meth_h|
                      li { a meth_s, :href => "javascript:;", :onclick => "open_helpsect('#{sect_cls}_#{meth_s}')" }
                    end
                  end
                end
              end
            end
          end
          div.howto! do
            div.help! do
              HacketyHack::DOCS.each do |sect_s, sect_h|
                sect_cls = sect_h['class']
                div :class => "helpsect #{sect_cls}", :style => "display:none" do
                  h1 sect_s
                  div.helptext do
                    div.summary { self << sect_h['description'] }
                  end
                end
                sect_h['sections'].each do |meth_s, doc|
                  div :class => "helpsect #{sect_cls}_#{meth_s}", :style => "display:none" do
                    h1 doc['title']
                    div.helptext do
                      div.summary { self << doc['description'] }
                      doc['methods'].each do |mname, expl|
                        h3 mname
                        div.meth { self << expl }
                      end
                    end
                  end
                end
              end
              div.intro.helpsect do
                h1 "Help"
                div.helptext do
                  p { text "So what can Hackety Hack do?  Look no further, this is a list of all of the most common
                     commands, organized so you can skip around quickly. <strong>Don't read all of this, just skim
                     for the stuff you really need.</strong>" }
                  img :src => "/static/screenshot-help-1.png"
                  h4 "How to Read The Help"
                  p "The most handy part of the help is all of the code examples.  This stuff is littered
                     with examples.  Such as:"
                  self << %{
                  <pre>robots = ["Trurl", "Klapaucius"] + ["R2-D2"]<br />robots  <span class="outputs">#=> ["Trurl", "Klapaucius", "R2-D2"]</span></pre>
                  <p>Okay, this example shows how to add two arrays.  But notice the green colored part?  Whenever
                  an example shows a green bit like that, you're seeing behind the scenes.  In this example, you're
                  seeing what's in the <code>robots</code> variable on the second line.</p>
                  <p>Think of the little <code>#=&gt;</code> symbol as a microscope which is pointed to the left
                  and is zooming in so you can magnify what's going on.</p>
                  }
                  h4 "Getting Back to This Page"
                  img.inline :src => "/static/hackety-logo.png"
                  p "Click on the books icon in the top right-hand corner to come back to this page.
                     Not that this page is really that useful, but you might be wondering anyway."
                  h4 "Finding What You Need"
                  p "So how do you find anything in this pile of stuff?"
                  ul do
                    li "Start with an object: a Number, a Web::Feed, a String"
                    li "Check that object's page for help on how to use it. (Checking a String's page will
                        show you all the basics, along with how to reverse it, count how long it is, capitalize it
                        and more.)"
                    li "If you can't find anything to help you, try turning the object into something else.
                        String.to_i can turn a String into an integer (a Number.)  Array.to_s can turn an Array
                        into a string.  Don't give up!"
                    li "If none of that works, hit Google and look for other people who are trying to do similiar
                        things.  You might hit a jackpot."
                  end
                  h4 "Remember: This Isn't Everything"
                  p { text "Again, this isn't a complete list of every method, just a condensed list of the most
                     common stuff.  For deeper reading, see <a href='http://rubycentral.com/book/builtins.html'>the
                     Ruby manual</a>." }
                end
              end
            end
          end
          div.headergrad! ''
          div.header! { a(:href => "javascript:;", :onclick => "open_helpsect('intro')") {
            img :src => "/static/hackety-logo.png" } }
        end
      end
    end
  end
end
