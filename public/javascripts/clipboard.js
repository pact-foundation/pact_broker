/**
 * Include code to enable copy-to-clipboard functionality
 * and currently used on index and matrix tables
 * @example in Haml
 *     %div.clippable
 *       = Text to be copied
 *       %button.clippy.hidden{ title: "Copy to clipboard" }
 *         %span.glyphicon.glyphicon-copy
 */

/**
 * Bootstrap copy-to-clipboard functionality
 * @param {string} selector CSS selector of elements that require
 *     copy-to-clipboard functionality
 */
function initializeClipper(selector) {
  const elements = $(selector);

  elements.hover(function() {
    $(this).children(".clippy").toggleClass("hidden");
  });

  elements
    .children(".clippy")
    .click(function() {
      const clippyButton = $(this);
      const text = $.trim(clippyButton.closest(selector).text());

      copyToClipboard(text);
      flashClipped(clippyButton);
    });
}

/**
 * Copy text to clipboard using execCommand
 * @see https://gist.github.com/Chalarangelo/4ff1e8c0ec03d9294628efbae49216db#file-copytoclipboard-js
 * @see https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand
 * @param {string} text text to be copied to clipboard
 */
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

/**
 * Flash a success tick to indicate successful copy-to-clipboard action
 * @param {jQuery Element} clipButton button to copy to clipboard
 */
function flashClipped(clippyButton) {
  const icon = clippyButton.children("span");
  icon.attr("class", "glyphicon glyphicon-ok success");

  setTimeout(
    function() { icon.attr("class", "glyphicon glyphicon-copy"); },
    2000
  );
}
