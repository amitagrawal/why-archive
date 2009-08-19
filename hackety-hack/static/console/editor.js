//the main function, call to the effect object
function dumpAlert(obj) {
    props = [];
    for ( var i in obj ) {
        props.push( "" + i + ": " + obj[i] );
    }
    alert( props );
}
window.onload = function() {
    window.irb = new MouseApp.Notepad('#irb', {
        rows: 13,
        name: 'IRB'
    });
}
