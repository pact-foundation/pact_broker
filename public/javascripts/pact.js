jQuery(function() {
    var longDateFormat  = 'E d MMM yyyy, h:mm p';
    var timezone = new Date().toString().match(/\(([A-Za-z\s].*)\)/)[1];


    $(document).ready(function(){
        jQuery(".longLocalDateFormat").each(function (idx, elem) {
            var localFormattedDate = jQuery.format.toBrowserTimeZone(jQuery(elem).text(), longDateFormat).replace(/\./g, '');
            jQuery(elem).text(localFormattedDate + " " + timezone);
        });
    });
});
