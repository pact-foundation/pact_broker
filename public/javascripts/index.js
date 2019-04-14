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

function handleDeletePactsSelected(clickedElement) {
  const tr = $(clickedElement).closest("tr");
  const confirmationText = createPactVersionsDeletionConfirmationText(tr.data());
  promptToDeleteResources(
    tr,
    tr.data().pactVersionsUrl,
    confirmationText
  );
}

function handleDeleteIntegrationsSelected(clickedElement) {
  const tr = $(clickedElement).closest("tr");
  const confirmationText = createIntegrationDeletionConfirmationText(
    tr.data()
  );
  promptToDeleteResources(
    tr,
    tr.data().integrationUrl,
    confirmationText
  );
}

function createIntegrationDeletionConfirmationText(rowData) {
  return `This will delete ${rowData.consumerName} and ${
    rowData.providerName
  }, and all associated data (pacts, verifications, application versions, tags and webhooks) that are not associated with other integrations. Do you wish to continue?`;
}

function promptToDeleteIntegration(rowData, row) {
  const agree = confirm(
    `This will delete ${rowData.consumerName} and ${
      rowData.providerName
    }, and all associated data (pacts, verifications, application versions, tags and webhooks). Do you wish to continue?`
  );
}

function highlightRowsToBeDeleted(table, consumerName, providerName) {
  table
    .children("tbody")
    .find(`[data-consumer-name="${consumerName}"]`)
    .children("td")
    .addClass("to-be-deleted");
  table
    .children("tbody")
    .find(`[data-provider-name="${providerName}"]`)
    .children("td")
    .addClass("to-be-deleted");
}

function highlightRowToBeDeleted(row) {
  row.children("td").addClass("to-be-deleted");
}

function unHighlightRows(table) {
  table.find(".to-be-deleted").removeClass("to-be-deleted");
}

function createPactVersionsDeletionConfirmationText(rowData) {
  return `This will delete all versions of the pact between ${
    rowData.consumerName
  } and ${rowData.providerName}. It will keep ${rowData.consumerName} and ${
    rowData.providerName
  }, and all other data related to them (webhooks, verifications, application versions, and tags). Do you wish to continue?`;
}

function confirmDeleteResources(
  rowData,
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

function promptToDeleteResources(row, deletionUrl, confirmationText) {
  const rowData = row.data();
  const table = row.closest("table");
  const cancel = function() {
    unHighlightRows(table);
  };
  const confirm = function() {
    deleteResources(
      deletionUrl,
      function() {
        handleDeletionSuccess(row);
      },
      function(response) {
        handleDeletionFailure(table, response);
      }
    );
  };

  highlightRowToBeDeleted(row);
  confirmDeleteResources(
    rowData,
    confirmationText,
    confirm,
    cancel
  );
}

function handleDeletionSuccess(row) {
  row
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

function handleDeletionFailure(table, response) {
  unHighlightRows(table);
  let errorMessage = null;

  if (response.error && response.error.message && response.error.reference) {
    errorMessage =
      "<p>Could not delete resources due to error: " +
      response.error.message +
      "</p><p>Error reference: " +
      response.error.reference + "</p>";
  } else {
    errorMessage =
      "Could not delete resources due to error: " + JSON.stringify(response);
  }

  $.alert({
      title: 'Error',
      content: errorMessage,
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
