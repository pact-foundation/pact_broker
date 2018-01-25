function handleRadioButtonClicked() {
  selectApplicableTextBox($(this));
  clearOtherTextBoxes($(this));
}

function selectApplicableTextBox(selectedRadioButton) {
  selectedRadioButton.closest('.input-group').find('input[type="text"]').first().focus();
}

function handleTextBoxClicked() {
  selectApplicableRadioButton($(this));
  clearOtherTextBoxes($(this));
}

function selectApplicableRadioButton(selectedTextBox) {
  selectedTextBox.closest('.input-group').find('.version-selectorizor').prop('checked', 'checked');
}

function clearOtherTextBoxes(clickedElement) {
  clickedElement.closest('.selector').find('input[type="text"]').each(function(){
    if(!$.contains(clickedElement.closest('.input-group')[0], $(this)[0])) {
      $(this).prop('value', '');
    }
  });
}

function onSubmit() {
  disableFieldsThatShouldNotBeSubmitted();
  return true;
}

function disableFieldsThatShouldNotBeSubmitted() {
  disableInputsForUncheckedRadioButtons();
  disableRadioButtons();
}

function disableInputsForUncheckedRadioButtons() {
  $('.version-selectorizor').each(function(){
    if($(this).prop('checked') === false) {
      $(this).closest('.input-group').find('input').prop('disabled', 'disabled');
    }
  });
}

function disableRadioButtons() {
  $('.version-selectorizor').prop('disabled', 'disabled');
}

$(document).ready(function(){
  $('.by-version').click(handleTextBoxClicked);
  $('.by-latest-tag').click(handleTextBoxClicked);
  $('.version-selectorizor').click(handleRadioButtonClicked);

  $("#matrix").tablesorter({
    textExtraction : function(node, table, cellIndex){
      n = $(node);
      return n.attr('data-sort-value') || n.text();
    }
  });


  $('[data-toggle="tooltip"]').each(function(index, el){
    $(el).tooltip({container: $(el)});
  });
});
