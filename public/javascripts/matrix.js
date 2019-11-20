function setTextboxVisibility(selectBox, cssSelector, visibility) {
  var textbox = selectBox.closest('.selector').find(cssSelector);
  textbox.toggle(visibility);
  if(visibility) {
    textbox.prop('disabled', '');
    textbox.focus();
  } else {
    textbox.prop('disabled', 'disabled');
  }
}

function toggleLatestFlag(selectBox, enabled) {
  var flagElement = selectBox.closest('.selector').find('.latest-flag');
  if(enabled) {
    flagElement.prop('disabled', '');
  } else {
    flagElement.prop('disabled', 'disabled');
  }
}

function showApplicableTextBoxes(selectorizor) {
  var selectorizorType = selectorizor.val();
  if( selectorizorType === 'specify-version') {
    setTextboxVisibility(selectorizor, '.version', true);
    setTextboxVisibility(selectorizor, '.tag', false);
  }
  else if( selectorizorType === 'specify-latest-tag' || selectorizorType === 'specify-all-tagged') {
    setTextboxVisibility(selectorizor, '.version', false);
    setTextboxVisibility(selectorizor, '.tag', true);
  }
  else if ( selectorizorType === 'specify-all-versions' || selectorizorType === 'specify-latest') {
    setTextboxVisibility(selectorizor, '.version', false);
    setTextboxVisibility(selectorizor, '.tag', false);
  }

  if (selectorizorType === 'specify-latest' || selectorizorType === 'specify-latest-tag') {
    toggleLatestFlag(selectorizor, true);
  } else {
    toggleLatestFlag(selectorizor, false);
  }
}

function handleSelectorizorChanged() {
  showApplicableTextBoxes($(this));
}

function onSubmit() {
  disableFieldsThatShouldNotBeSubmitted();
  return true;
}

function disableFieldsThatShouldNotBeSubmitted() {
  $('.version-selectorizor').prop('disabled', 'disabled');
}

function highlightPactPublicationsWithSameContent(td) {
  const pactVersionSha = $(td).data('pact-version-sha');
  $('*[data-pact-version-sha="' + pactVersionSha +'"]').addClass('bg-info');
}

function unHighlightPactPublicationsWithSameContent(td, event) {
  var destinationElement = $(event.toElement || event.relatedTarget);
  // Have to use mouseout instead of mouseleave, because the tooltip is a child
  // of the td, and the mouseleave will consider that hovering over the tooltip
  // does not count as leaving. Unfortunately, if you then leave the tooltip,
  // the div gets removed without firing the mouseleave event, so the cells remain
  // highlighted.
  // The tooltip needs to be a child of the td so that we can style the one showing
  // the SHA so that it's wide enough to fit the SHA in.
  if (!$(td).find('a').is(destinationElement)) {
    const pactVersionSha = $(td).data('pact-version-sha');
    $('*[data-pact-version-sha="' + pactVersionSha +'"]').removeClass('bg-info');
  }
}

$(document).ready(function(){
  $('.version-selectorizor').change(handleSelectorizorChanged);
  $('.version-selectorizor').each(function(){ showApplicableTextBoxes($(this)); });

  $("#matrix").tablesorter({
    textExtraction : function(node, table, cellIndex){
      n = $(node);
      return n.attr('data-sort-value') || n.text();
    }
  });

  $('[data-toggle="tooltip"]').each(function(index, el){
    $(el).tooltip({container: $(el)})
  });

  initializeClipper('.clippable');

  $('td.pact-published').mouseover(function(event) { highlightPactPublicationsWithSameContent(this) });
  $('td.pact-published').mouseout(function(event) { unHighlightPactPublicationsWithSameContent(this, event)});
});
