var gmail = {};

gmail.listMessages = function(selector, labelNames, displayCount) {
  var self = this;

  if (gapi.auth2 && gapi.auth2.getAuthInstance().isSignedIn.get()) {
    gapi.client.gmail.users.labels.list({
      userId: 'me'
    }).then(function(response) {
      var labels = new Map();
      for (var i = 0; i < response.result.labels.length; i ++) {
        var l = response.result.labels[i];
        labels.set(l.name, l.id);
      }

      var labelIds = [];
      for (var i = 0; i < labelNames.length; i ++) {
        labelIds.push(labels.get(labelNames[i]));
      }

      gapi.client.gmail.users.threads.list({
        userId: 'me',
        labelIds: labelIds,
        maxResults: displayCount
      }).then(function(response) {
        self._appendMessages(selector, response.result.threads);
      });
    });
  } else {
    setTimeout(function() {
      self.listMessages(selector, labelNames, displayCount);
    }, 100);
  }
};

gmail._appendMessages = function(selector, threads) {
  var messages = new Map();

  for (i = 0; i < threads.length; i++) {
    var thread = threads[i];
    messages.set(thread.id, null);

    gapi.client.gmail.users.threads.get({
      userId: 'me',
      id: thread.id,
      format: 'metadata',
      metadataHeaders: ['From', 'Subject']
    }).then(function(response) {
      messages.set(response.result.id, response.result.messages[0]);
    });
  }

  this._retrieveMessages(selector, messages);
};

gmail._retrieveMessages = function(selector, messages) {
  var self = this;

  if (self._checkMessages(messages)) {
    self._clearMessages(selector);

    for (var message of messages.values()) {
      var from = null;
      var subject = null;
      for (i = 0; i < message.payload.headers.length; i++) {
        var header = message.payload.headers[i];
        if (header.name == 'From') {
          from = header.value;
        }
        if (header.name == 'Subject') {
          subject = header.value;
        }
      }
      self._appendMessage(selector, from, subject);
    }
  } else {
    setTimeout(function() {
      self._retrieveMessages(selector, messages);
    }, 100);
  }
};

gmail._clearMessages = function(selector) {
  var ol = document.getElementById(selector);
  while (ol.firstChild) {
    ol.removeChild(ol.firstChild);
  }
};

gmail._appendMessage = function(selector, from, subject) {
  var ol = document.getElementById(selector);
  var li = document.createElement('li');
  var title = document.createAttribute("title");
  title.value = from;
  li.attributes.setNamedItem(title);
  li.appendChild(document.createTextNode(subject));
  ol.appendChild(li);
};

gmail._checkMessages = function(messages) {
  for (var message of messages.values()) {
    if (!message) {
      return false;
    }
  }
  
  return true;
};
