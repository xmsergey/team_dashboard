$(function() {
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

function clearImage() {
  var id = $('#hidden_input').val();
  var img = new Image();
  img.src = $('#avatar_' + id).attr('src');
  $('#target').html(img);
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
        if (confirm('Are you sure?')){
          $.ajax({
            method: 'POST',
            url: 'team_dashboard/remove_image',
            data: { user_id: id }
          }).done(function(){
            avatar_popup.dialog('destroy');
            location.reload();
          });
        }
      },
      Save: function () {
        var formData = new FormData();
        formData.append('file', $('#pictureInput').prop("files")[0]);
        formData.append('id', id);
        $.ajax({
          method: 'POST',
          url: 'team_dashboard/upload_image',
          data: formData,
          processData: false,
          contentType: false
        }).done(function(){
          avatar_popup.dialog('destroy');
          location.reload();
        })
      },
      Close: function () {
        avatar_popup.dialog('destroy');
      }
    }
  }).dialog('open');
}