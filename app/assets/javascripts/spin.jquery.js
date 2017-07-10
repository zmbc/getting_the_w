(function($) {
  $.fn.spin = function(spin, opts) {
    if (opts === undefined) {
      opts = {
        lines: 13, // The number of lines to draw
        length: 20, // The length of each line
        width: 10, // The line thickness
        radius: 30, // The radius of the inner circle
        corners: 1, // Corner roundness (0..1)
        rotate: 0, // The rotation offset
        direction: 1, // 1: clockwise, -1: counterclockwise
        color: '#000', // #rgb or #rrggbb or array of colors
        speed: 1, // Rounds per second
        trail: 56, // Afterglow percentage
        shadow: false, // Whether to render a shadow
        hwaccel: false, // Whether to use hardware acceleration
        className: 'spinner', // The CSS class to assign to the spinner
        zIndex: 2e9, // The z-index (defaults to 2000000000)
        top: '50%', // Top position relative to parent
        left: '50%' // Left position relative to parent
      };
    }

    var container = $(this);
    var data = container.data();

    if (data.spinner) {
      data.spinner.stop();
      delete data.spinner;
      container.find(".spinner_modal").remove();
      return this;
    }

    if (spin) {
      container.css('position', 'relative');
      container.append('<div class="spinner_modal" style="background-color: rgba(0, 0, 0, 0.1); width:100%; height:100%; position:absolute; top:0px; left:0px; z-index:' + (opts.zIndex - 1) + '"/>');
      var spinner = container.find('.spinner_modal')[0];
      data.spinner = new Spinner($.extend({
        color: container.css('color')
      }, opts)).spin(spinner);
    }
  };
})(jQuery);
