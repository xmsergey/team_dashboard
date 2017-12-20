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
  var id = $('#hidden_input').val();
  var img = new Image();
  removePhoto(id, img, true);
  $('#pictureForm')[0].reset();
}

function sendAvatar(id){
  var avatar_popup = $('#avatar_popup');

  var img = new Image();
  img.src = $('#avatar_' + id).attr('src');
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
          $.ajax({
            method: 'POST',
            url: 'team_dashboard/remove_image',
            data: { user_id: id }
          }).done(function(response){
            if (response.error_messages !== undefined && response.error_messages !== ""){
              alert(response.error_messages);
              $('#avatar_popup').parent().css('z-index', 999);
            }else{
              avatar_popup.dialog('destroy');
              window.location = window.location;
            }
          }).fail(function(response){
            avatar_popup.dialog('destroy');
            window.location = window.location;
          });
        }
      },
      'Save': function(){
        avatar_popup.parent().css('z-index', 1);
        var formData = new FormData();
        formData.append('file', $('#pictureInput').prop("files")[0]);
        formData.append('id', id);
        $.ajax({
          method: 'POST',
          url: 'team_dashboard/upload_image',
          data: formData,
          processData: false,
          contentType: false
        }).done(function(response){
          if (response.error_messages !== undefined && response.error_messages !== ""){
            $('#avatar_popup').parent().css('z-index', 999);
            alert(response.error_messages);
          }else{
            avatar_popup.dialog('destroy');
            safeRedirect();
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
    method: 'POST',
    url: 'team_dashboard/remove_image',
    data: { user_id: id, clear_image: clear_image }
  }).done(function(response){
    if (response.error_messages !== undefined && response.error_messages !== ""){
      alert(response.error_messages);
      $('#avatar_popup').parent().css('z-index', 999);
    }else{
      if (clear_image) {
        $('#avatar_' + id).parent().html(response);
        img.src = $('#avatar_' + id).attr('src');
        $('#target').html(img);
      } else {
        safeRedirect();
      }
    }
  }).fail(function(response){
    safeRedirect();
  });
}

function safeRedirect() {
  window.location = window.location.origin + window.location.pathname + '?' + $('#sidebar form div.filter-block :input').serialize();
}
