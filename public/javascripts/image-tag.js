var _listCount = 20,
    _updateImageListThreshold = 10,
    _imageIds = [];

var appendImages = function (data) {
  $(data).each(function (index, image) {
    var listItem = '<li data-image-id="' + image.image.id + '"><img src="' + image.image.url + '" /></li>';
    $('#images').append(listItem);
    _imageIds.push(image.image.id);
  });
};

var updateImage = function (approved) {
  var imageId = _imageIds.shift();
  var imageItem = $('#images li[data-image-id=' + imageId + ']');
  if (imageItem.length === 0) return false;
  $.post('/update/' + imageId, {approved: approved, _method: 'PUT'}, function (data) {
    updateImageList(imageId);
    increaseScore(approved);
  });
  imageItem.slideUp('fast', function () {
    imageItem.remove();
  });
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

  ipsCount = $('body').data('ips-count');
  $('body').data('ips-count', Number(ipsCount) + 1);
  $('#remaining-count').html($('body').data('count') - (ipsCount + 1));
  $("#" + name + " .score").html(newScore);
};

$('#accepted').click(function () {
  updateImage(1);
});

$('#declined').click(function () {
  updateImage(0);
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
  // enter => decline
  if (event.keyCode == 13 || event.keyCode == 32) {
    event.preventDefault();
    event.stopPropagation();
    return false;
  }
});

$.getJSON('/next/' + _listCount, appendImages);




