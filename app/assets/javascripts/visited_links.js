(function () {
  $(document).on('click.visitedLinks', '.gadget ol li a[href]', function () {
    var url = this.href.replace(/#.*$/, '');
    $(this).addClass('link--visited');
    $.post('/visited_links', { url: url });
  });
})();
