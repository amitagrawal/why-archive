
/* Irb running moush */
MouseApp.Irb = function(element, options) {
  this.element = $(element);
  this.setOptions(options);
  this.showHelp = this.options.showHelp;
  if ( this.options.showChapter ) {
      this.showChapter = this.options.showChapter;
  }
  if ( this.options.init ) {
      this.init = this.options.init;
  }
  this.initWindow();
  this.setup();
  this.helpPage = null;
  this.irbInit = false;
};

$.extend(MouseApp.Irb.prototype, MouseApp.Terminal.prototype, {
    cmdToQuery: function(cmd) {
        return "cmd=" + escape(cmd.replace(/&lt;/g, '<').replace(/&gt;/g, '>').
            replace(/&amp;/g, '&').replace(/\r?\n/g, "\n")).replace(/\+/g, "%2B");
    },

    fireOffCmd: function(cmd, func) {
        $.ajax({url: this.options.irbUrl + "?" + this.cmdToQuery(cmd), type: "GET", complete: func});
    },

    reply: function(str) {
        var raw = str.replace(/\033\[(\d);(\d+)m/g, '');
        this.checkAnswer(raw);
        if (str != "..") {
            if ( str[str.length - 1] != "\n" ) {
                str += "\n";
            }
            js_payload = /\033\[1;JSm(.*)\033\[m/;
            js_in = str.match(js_payload);
            if (js_in) {
                try {
                    js_in = eval(js_in[1]);
                } catch (e) {}
                str = str.replace(js_payload, '');
            }
            var pr_re = new RegExp("(^|\\n)=>");
            if ( str.match( pr_re ) ) {
              str = str.replace(new RegExp("(^|\\n)=>"), "$1\033[1;34m=>\033[m");
            } else {
              str = str.replace(new RegExp("(^|\\n)= (.+?) ="), "$1\033[1;33m$2\033[m");
            }
            this.write(str);
            this.prompt();
        } else {
            this.prompt("\033[1;32m..\033[m", true);
        }
    },

    setHelpPage: function(n, page) {
        if (this.helpPage)
          $(this.helpPage.ele).hide('fast');
        this.helpPage = {index: n, ele: page};
        $(page).show('fast');
    },

    scanHelpPageFor: function(eleClass) {
        match = $("div." + eleClass, this.helpPage.ele);
        if ( match[0] ) return match[0].innerHTML;
        else            return -1;
    },

    checkAnswer: function(str) {
        if ( this.helpPage ) {
            match = this.scanHelpPageFor('answer');
            if ( match != -1 ) {
                if ( str.match( new RegExp('^\s*=> ' + match + '\s*$', 'm') ) ) {
                    this.showHelp(this.helpPage.index + 1);
                }
            } else {
                match = this.scanHelpPageFor('stdout');
                if ( match != -1 ) {
                    if ( match == '' ) {
                        if ( str == '' || str == null ) this.showHelp(this.helpPage.index + 1);
                    } else if ( str.match( new RegExp('^\s*' + match + '$', 'm') ) ) {
                        this.showHelp(this.helpPage.index + 1);
                    }
                }
            }
        }
    },

    onKeyCtrld: function() {
        this.clearCommand();
        this.puts("reset");
        this.onKeyEnter();
    },

    onKeyEnter: function() {
        this.typingOff();
        var cmd = this.getCommand();
        if (cmd) {
            this.history[this.historyNum] = cmd;
            this.backupNum = ++this.historyNum;
        }
        this.commandNum++;
        this.advanceLine();
        if (cmd) {
            if ( cmd == "clear" ) {
                this.clear();
                this.prompt();
            } else if ( cmd.match(/^(back)$/) ) {
                if (this.helpPage && this.helpPage.index >= 1) {
                    this.showHelp(this.helpPage.index - 1);
                }
                this.prompt();
            } else if ( cmd.match(/^(help|wtf\?*)$/) ) {
                this.showHelp(1);
                this.prompt();
            } else if ( regs = cmd.match(/^(help|wtf\?*)\s+#?(\d+)\s*$/) ) {
                this.showChapter(parseInt(regs[2]));
                this.prompt();
            } else {
                var term = this;
                this.fireOffCmd(cmd);
            }
        } else {
            this.prompt();
        }
    }
});

