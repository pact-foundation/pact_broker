/**
 * Include code to enable copy-to-clipboard functionality
 * and currently used on index and matrix tables
 * @example in Haml
 *     %div.clippable
 *       = Text to be copied
 *       %button.clippy.invisible{ title: "Copy to clipboard" }
 *         %span.copy-icon
 */

/**
 * Bootstrap copy-to-clipboard functionality
 * @param {string} selector CSS selector of elements that require
 *     copy-to-clipboard functionality
 */
function initializeClipper(selector) {
  const elements = $(selector);

  elements.hover(function() {
    $(this).children(".clippy").toggleClass("invisible");
  });

  elements
    .children(".clippy")
    .click(function() {
      const clippyButton = $(this);
      const clipTarget = clippyButton.closest(selector);
      let text = null;
      if(clipTarget.data('clippable')) {
        text = clipTarget.data('clippable');
      } else {
        text = clippyButton.closest(selector).text();
      }
      copyToClipboard($.trim(text));

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
  icon.attr("class", "copy-success-icon");

  setTimeout(
    function() { icon.attr("class", "copy-icon"); },
    2000
  );
}
