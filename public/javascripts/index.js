$(document).ready(function() {
  $(".integration-settings")
    .materialMenu("init", {
      position: "overlay",
      animationSpeed: 1,
      items: [
        {
          type: "normal",
          text: "Delete pacts ...",
          click: handleDeletePactsSelected
        },
        {
          type: "normal",
          text: "Delete integration...",
          click: handleDeleteIntegrationsSelected
        }
      ]
    })
    .click(function() {
      $(this).materialMenu("open");
    });
});

function createPactDeletionConfirmationText(rowData) {
  return `This will delete all versions of the pact between ${
    rowData.consumerName
  } and ${rowData.providerName}. It will keep ${rowData.consumerName} and ${
    rowData.providerName
  }, and all other data related to them (webhooks, verifications, application versions, and tags). Do you wish to continue?`;
}

function createIntegrationDeletionConfirmationText(rowData) {
  return `This will delete ${rowData.consumerName} and ${
    rowData.providerName
  }, and all associated data (pacts, verifications, application versions, tags and webhooks) that are not associated with other integrations. Do you wish to continue?`;
}

function handleDeletePactsSelected(clickedElement) {
  const tr = $(clickedElement).closest("tr");
  const confirmationText = createPactDeletionConfirmationText(tr.data());
  handleDeleteResourcesSelected(
    tr,
    tr.data().pactVersionsUrl,
    confirmationText
  );
}

function handleDeleteIntegrationsSelected(clickedElement) {
  const tr = $(clickedElement).closest("tr");
  const confirmationText = createIntegrationDeletionConfirmationText(tr.data());
  handleDeleteResourcesSelected(tr, tr.data().integrationUrl, confirmationText);
}

function findRowsToBeDeleted(table, consumerName, providerName) {
  return table
    .children("tbody")
    .find(
      `[data-consumer-name="${consumerName}"][data-provider-name="${providerName}"]`
    );
}

function highlightRowsToBeDeleted(rows) {
  rows.children("td").addClass("to-be-deleted");
}

function unHighlightRows(rows) {
  rows.children("td").removeClass("to-be-deleted");
}

function confirmDeleteResources(
  confirmationText,
  confirmCallback,
  cancelCallback
) {
  $.confirm({
    title: "Confirm!",
    content: confirmationText,
    buttons: {
      delete: {
        text: "DELETE",
        btnClass: "alert alert-danger",
        keys: ["enter", "shift"],
        action: confirmCallback
      },
      cancel: cancelCallback
    }
  });
}

function handleDeleteResourcesSelected(row, deletionUrl, confirmationText) {
  const rowData = row.data();
  const rows = findRowsToBeDeleted(
    row.closest("table"),
    rowData.consumerName,
    rowData.providerName
  );
  const cancelled = function() {
    unHighlightRows(rows);
  };
  const confirmed = function() {
    deleteResources(
      deletionUrl,
      function() {
        handleDeletionSuccess(rows);
      },
      function(response) {
        handleDeletionFailure(rows, response);
      }
    );
  };
  highlightRowsToBeDeleted(rows);
  confirmDeleteResources(confirmationText, confirmed, cancelled);
}

function hideDeletedRows(rows) {
  rows
    .children("td, th")
    .animate({ padding: 0 })
    .wrapInner("<div />")
    .children()
    .slideUp(function() {
      $(this)
        .closest("tr")
        .remove();
    });
}

function handleDeletionSuccess(rows) {
  hideDeletedRows(rows);
}

function createErrorMessage(responseBody) {
  if (responseBody && responseBody.error && responseBody.error.message && responseBody.error.reference) {
    return `<p>Could not delete resources due to error: ${
      responseBody.error.message
    }</p><p>Error reference:
      ${responseBody.error.reference}
      </p>`;
  } else if (responseBody) {
    return `Could not delete resources due to error: ${JSON.stringify(responseBody)}`;
  }

  return "Could not delete resources.";
}

function handleDeletionFailure(rows, response) {
  unHighlightRows(rows);
  $.alert({
    title: "Error",
    content: createErrorMessage(response)
  });
}

function deleteResources(url, successCallback, errorCallback) {
  $.ajax({
    url: url,
    dataType: "json",
    type: "delete",
    accepts: {
      text: "application/hal+json"
    },
    success: function(data, textStatus, jQxhr) {
      successCallback();
    },
    error: function(jqXhr, textStatus, errorThrown) {
      errorCallback(jqXhr.responseJSON);
    }
  });
}


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
      const text = $.trim($(this).closest(".clippable").text());
      copyToClipboard(text);
    });
}
