var _listCount = 20,
    _updateImageListThreshold = 10,
    _imageIds = [];

var flash = function (message) {
  flashDiv = $('#flash');
  flashDiv.html(message);
  flashDiv.slideDown('fast');
  setTimeout(function () {
    flashDiv.slideUp('fast');
  }, 3000);
};

var appendImages = function (data) {
  images = data.images;
  remaining = data.remaining;
  $(images).each(function (index, image) {
    var listItem = '<li data-image-url="' + image.image.url + '" data-image-id="' + image.image.id + '"><img width="500" src="' + image.image.url + '" /></li>';
    $('#images').append(listItem);
    _imageIds.push(image.image.id);
  });
  $('#remaining-count').html(remaining);
};

var addToUndoList = function (image, approved) {
  var undoList = $('#undo-list');
  listItem = $('<li><img class="undo-image" height="200" src="' + image.data('image-url') + '" /><button class="declined" data-image-id="' + image.data('image-id') + '">FACE!</button><button class="accepted" data-image-id="' + image.data("image-id") + '">no face</button></li>');
  undoList.prepend(evaluateApprovedClass(listItem, approved));
  while (undoList.children().length > 10) {
    undoList.children().last().remove();
  }
};

var evaluateApprovedClass = function (listItem, approved) {
  approvedClass = approved ? 'is-approved' : 'is-declined';
  $(listItem).removeClass('is-declined');
  $(listItem).removeClass('is-approved');
  $(listItem).addClass(approvedClass);
  return listItem;
};

var updateImage = function (approved, imageId) {
  if (typeof imageId === 'undefined') {
    imageId = _imageIds.shift();
    var imageItem = $('#images li[data-image-id=' + imageId + ']');
    if (imageItem.length === 0) return false;
    $.post('/update/' + imageId, {approved: approved, _method: 'PUT'}, function (data) {
      updateImageList(imageId);
      addToUndoList(imageItem, approved);
      increaseScore(approved);
    });
    imageItem.slideUp('fast', function () {
      imageItem.remove();
    });
  } else {
    $.post('/update/' + imageId, {approved: approved, _method: 'PUT'}, function (data) {
      flash('Notice: Image updated.');
    });
  }
  return false;
};

var updateImageList = function (imageId) {
  if ($('#images li').length <= _updateImageListThreshold) {
    var lastImage = $('#images li').last();
    $.get('/next/' + (_listCount - _updateImageListThreshold) + '?last_id=' + lastImage.data('image-id'), appendImages);
  }
};

var increaseScore = function (approved) {
  var name;
  if (approved) {
    name = "accepted";
  } else {
    name = "declined";
  }
  var newScore = Number($('body').data(name)) + 1;
  $('body').data(name, newScore);

  // ipsCount = $('body').data('ips-count');
  // $('body').data('ips-count', Number(ipsCount) + 1);
  // $('#remaining-count').html($('body').data('count') - (ipsCount + 1));
  $("#" + name + " .score").html(newScore);
};

$('#accepted').click(function () {
  updateImage(1);
});

$('#declined').click(function () {
  updateImage(0);
});

$('.declined[data-image-id]').live('click',function () {
  updateImage(1, $(this).data('image-id'));
  listItem = $(this).closest('li');
  evaluateApprovedClass(listItem, false);
  setTimeout(toggleUndoHandle, 200);
});
$('.accepted[data-image-id]').live('click',function () {
  updateImage(0, $(this).data('image-id'));
  listItem = $(this).closest('li');
  evaluateApprovedClass(listItem, true);
  setTimeout(toggleUndoHandle, 200);
});

var toggleUndoHandle = function () {
  if ($('#undo-list li').length > 0) {
    $('#undo-list').slideToggle('fast');
    $('#undo .handle').toggleClass('opened');
  }
};

$('#undo .handle').click(function () {
  toggleUndoHandle();
});

$(document).keyup(function (event) {
  var stop = false;
  // enter => decline
  if (event.keyCode == 13) {
    updateImage(0);
    stop = true;
  // space => accept
  } else if (event.keyCode == 32) {
    updateImage(1);
    stop = true;
  }
  if (stop) {
    event.preventDefault();
    event.stopPropagation();
  }
  return false;
});

$(document).keypress(function (event) {
  if (event.keyCode == 13 || event.keyCode == 32) {
    event.preventDefault();
    event.stopPropagation();
    return false;
  }
});

$.getJSON('/next/' + _listCount, appendImages);

