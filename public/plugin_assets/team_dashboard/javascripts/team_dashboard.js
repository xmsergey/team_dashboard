$(function(){
  $('#pictureInput').on('change', function(event) {
    var files = event.target.files;
    var image = files[0];
    var reader = new FileReader();
    reader.onload = function(file) {
      var img = new Image();
      img.src = file.target.result;
      $('#target').html(img);
    };
    reader.readAsDataURL(image);
  });
});

function clearImage(){
  if (!confirm('Are you sure?')) return;
  var id = $('#hidden_input').val();
  var img = new Image();
  removePhoto(id, img, true);
  $('#pictureForm')[0].reset();
  $('#avatar_popup').dialog('destroy');
}

function sendAvatar(id){
  var avatar_popup = $('#avatar_popup');

  var img = new Image();
  var avatar = $('#avatar_' + id);
  img.src = avatar.attr('src');
  $('#target').html(img);
  $('#pictureForm')[0].reset();
  $('#hidden_input').val(id);

  avatar_popup.dialog({
    dialogClass: 'ticket-ui-dialog',
    title: 'Choose Photo',
    width: 600,
    height: 600,
    modal: true,
    overflow: 'auto',
    autoOpen: false,
    closable: true,
    buttons: {
      'Remove photo': function(){
        avatar_popup.parent().css('z-index', 1);
        if (confirm('Are you sure?')){
          removePhoto(id, img);
          avatar_popup.dialog('destroy');
        }
      },
      'Save': function(){
        avatar_popup.parent().css('z-index', 1);
        var formData = new FormData();
        formData.append('file', $('#pictureInput').prop("files")[0]);

        $.ajax({
          method: 'POST',
          url: 'team_dashboard/photo/' + id + '/create',
          data: formData,
          processData: false,
          contentType: false
        }).done(function(response){
          if (response.error_messages !== undefined && response.error_messages !== ""){
            $('#avatar_popup').parent().css('z-index', 999);
            alert(response.error_messages);
          }else{
            avatar_popup.dialog('destroy');
            $('#avatar_' + id).attr('src', response.image_src);
          }
        }).fail(function(response){
          avatar_popup.dialog('destroy');
          safeRedirect();
        })
      },
      'Close': function(){
        avatar_popup.dialog('destroy');
      }
    }
  }).dialog('open');
}

function removePhoto(id, img, clear_image) {
  $.ajax({
    method: 'DELETE',
    url: 'team_dashboard/photo/' + id
  }).done(function(response){
    if (response.error_messages !== undefined && response.error_messages !== ""){
      alert(response.error_messages);
      $('#avatar_popup').parent().css('z-index', 999);
    }else{
      $('#avatar_' + id).attr('src', response.image_src);
    }
  }).fail(function(response){
    safeRedirect();
  });
}

function safeRedirect() {
  window.location = window.location.origin + window.location.pathname + '?' + $('#sidebar form div.filter-block :input').serialize();
}

function truncateIssuesNames() {
  $('.truncate').each(function() {
    var adj = 0;
    adj += $(this).closest('.col-desc').find('.eta').width();
    adj += $(this).closest('.col-desc').find('.initials').width();
    if (adj) adj += 7;
    $(this).css('width', $(this).closest('.col-desc').width() - adj);
  });
}

function disableFields(checkbox) {
  if (checkbox.checked){
    $('.support_disabled').each(function(){
      this.style.opacity = 0.6;
      this.querySelector('select, input[type=checkbox]').disabled = true;
    });
  }else{
    $('.support_disabled').each(function(){
      this.style.opacity = 1;
      this.querySelector('select, input[type=checkbox]').disabled = false;
    });
  }
}

function addToTeam(theSelFrom, theSelTo) {
  var selectedUsers = $(theSelFrom).find('option:selected').clone();
  selectedUsers.each(function(){
    if (!userInGroup(this, theSelTo)) {
      $(this).appendTo($(theSelTo));
    }
  });
}

function removeFromTeam(theSelFrom) {
  $(theSelFrom).find('option:selected').remove();
}

function userInGroup(user, group) {
  return $(group).find('option[value=' + user.value + ']').length > 0;
}
