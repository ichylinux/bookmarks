var feeds = {};

feeds.get_feed_title = function(button) {
  var form = $(button).closest('form');

  var url = form.find('input[name*="feed_url"]').val();
  if (url == '') {
    alert('フィードURLを先に入力してください。');
    return;
  }
  
  var params = form.serializeArray();
  for (var i = 0; i < params.length; i ++) {
    if (params[i].name == 'id') {
      params[i].value = null;
    } else if (params[i].name == '_method') {
      params[i].value = 'post';
    }
  }

  $.post($(button).data('url'), params, function(title) {
    if ($.trim(title) == '') {
      alert('フィードを取得できませんでした。');
      return;
    }
    form.find('input[name*="title"]').val(title);
  });
};
