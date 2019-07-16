// https://gist.github.com/Chalarangelo/4ff1e8c0ec03d9294628efbae49216db#file-copytoclipboard-js
function copyToClipboard(text) {
  const el = document.createElement('textarea');
  el.value = text;
  el.setAttribute('readonly', '');
  el.style.position = 'absolute';
  el.style.left = '-9999px';
  document.body.appendChild(el);

  const selected =
        document.getSelection().rangeCount > 0
        ? document.getSelection().getRangeAt(0)
        : false;
  el.select();
  document.execCommand('copy');
  document.body.removeChild(el);
  if (selected) {
    document.getSelection().removeAllRanges();
    document.getSelection().addRange(selected);
  }
}

function clipper() {
  const elements = $(".clippable");

  elements.hover(function() {
    $(this).children(".clippy").toggleClass("hidden");
  });

  elements
    .children(".clippy")
    .click(function() {
      const clippyButton = $(this);
      const text = $.trim(clippyButton.closest(".clippable").text());

      copyToClipboard(text);
      flashClipped(clippyButton);
    });
}

function flashClipped(clippyButton) {
  const icon = clippyButton.children("span");
  icon.attr("class", "glyphicon glyphicon-ok success");

  setTimeout(
    function() { icon.attr("class", "glyphicon glyphicon-copy"); },
    2000
  );
}
