var allStretch;
var helpPages;
var chapPages;
var defaultPage;
var toot = window.location.search.substr(1)

//the main function, call to the effect object
function dumpAlert(obj) {
    props = [];
    for ( var i in obj ) {
        props.push( "" + i + ": " + obj[i] );
    }
    alert( props );
}
window.onload = function() {
    defaultPage = $('#helpstone .stretcher').html();

    window.irb = new MouseApp.Irb('#irb', {
        rows: 13,
        name: 'IRB',
        greeting: "%+r Interactive ruby ready. %-r",
        ps: '\033[1;32m>>\033[m',
        user: 'guest',
        host: 'tryruby',
        irbUrl: '/irb',
        init: function () {
            helpPages = $(".stretcher");
            chapPages = new Array();
            for (var i = 0; i < helpPages.length; i++ ) {
                var cls = helpPages[i].className.split(' ');
                for (var j = 0; j < cls.length; j++) {
                    if (cls[j] == 'chapmark') {
                        chapPages.push([i, helpPages[i]]);
                        break;
                    }
                }
            }
        },
        loadTutorial: function (id, instruct) {
            $.ajax({
                url: '/static/console/tutorials/' + id + '.html',
                type: 'GET', 
                complete: function (r) {
                    $('#helpstone').html("<div class='stretcher chapmark'>" + defaultPage + "</div>" + r.responseText);
                    window.irb.init();
                    window.irb.showHelp(0);
                }
            });
        },
        showChapter: function (n) {
            if (n >= chapPages.length) return;
            this.setHelpPage(chapPages[n][0], chapPages[n][1]);
        },
        showHelp: function (n) {
            if (n >= helpPages.length) return;
            this.setHelpPage(n, helpPages[n]);
        },
        popup_goto: function (u) {
            $('#lilBrowser').show().css({left: '40px', top: '40px'});
            $('#lbIframe').attr('src', u);
        },
        popup_make: function (s) {
            $('#lilBrowser').show().css({left: '40px', top: '40px'});
            $('#lbIframe').get(0).onIframeLoad = function () { 
                return s;
            };
            $('#lbIframe').attr({src: '/blank.html'});
        },
        popup_close: function () {
            $('#lilBrowser').hide();
        }
    });

    if ( !toot ) {
        toot = 'intro';
    }
    try {
        window.irb.options.loadTutorial( toot, true );
    } catch (e) {}
}
