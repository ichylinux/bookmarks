var feeds = {};

feeds.get_feed_title = function(button) {
  var form = $(button).closest('form'); 
  var url = form.find('input[name*="url"]').val();
  if (url == '') {
    alert('フィードURLを先に入力してください。');
    return;
  }
  
  $.post($(button).data('url'), {url: url}, function(title) {
    if ($.trim(title) == '') {
      alert('フィードを取得できませんでした。');
      return;
    }
    form.find('input[name*="title"]').val(title);
  });
};
