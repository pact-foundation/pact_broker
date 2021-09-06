$(document).ready(function() {
  $(".integration-settings").click(function() {
    const clickedElementData = $(this).closest("tr").data();
    $(this).materialMenu("init", {
      position: "overlay",
      animationSpeed: 1,
      items: buildMaterialMenuItems(clickedElementData)
    });
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

function createPactTagDeletionConfirmationText({
  providerName,
  consumerName,
  pactTagName
}) {
  return `This will delete the pacts for provider ${providerName} and all versions of ${
    consumerName
  } with tag ${pactTagName}. Do you wish to continue?`;
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

function handleDeleteTagSelected({
  providerName,
  consumerName,
  pactTagName,
  deletionUrl
}) {
  return function(clickedElement) {
    const tr = $(clickedElement).closest("tr");
    const confirmationText = createPactTagDeletionConfirmationText({
      providerName,
      consumerName,
      pactTagName
    });
    handleDeleteResourcesSelected(
      tr,
      deletionUrl,
      confirmationText,
      pactTagName
    );
  };
}

function findRowsToBeDeleted(table, consumerName, providerName, tagName) {
  if (!tagName) {
    return table
            .children("tbody")
            .find(
              `[data-consumer-name="${consumerName}"][data-provider-name="${providerName}"]`
            );
  }

  return table
          .children("tbody")
          .find("tr")
          .find("td")
          .filter(function() {
            return $(this)
              .text()
              .includes(`tag: ${tagName}`);
          })
          .closest("tr");
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

function handleDeleteResourcesSelected(
  row,
  deletionUrl,
  confirmationText,
  tagName
) {
  const rowData = row.data();
  const rows = findRowsToBeDeleted(
    row.closest("table"),
    rowData.consumerName,
    rowData.providerName,
    tagName
  );
  const isRefreshingThePage = !!tagName;
  const cancelled = function() {
    unHighlightRows(rows);
  };
  const confirmed = function() {
    deleteResources(
      deletionUrl,
      function() {
        handleDeletionSuccess(rows, isRefreshingThePage);
      },
      function(response) {
        handleDeletionFailure(rows, response);
      }
    );
  };

  if (!isRefreshingThePage) {
    highlightRowsToBeDeleted(rows);
  }
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

function refreshPage() {
  const url = new URL(window.location);
  url.searchParams.delete("search");
  window.location = url.toString();
}

function handleDeletionSuccess(rows, isRefreshingThePage) {
  if (isRefreshingThePage) {
    return refreshPage();
  }

  hideDeletedRows(rows);
}

function createErrorMessage(responseBody) {
  if (
    responseBody &&
    responseBody.error &&
    responseBody.error.message &&
    responseBody.error.reference
  ) {
    return `<p>Could not delete resources due to error: ${responseBody.error.message}</p><p>Error reference:
      ${responseBody.error.reference}
      </p>`;
  } else if (responseBody) {
    return `Could not delete resources due to error: ${JSON.stringify(
      responseBody
    )}`;
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
    success: function() {
      successCallback();
    },
    error: function(jqXhr) {
      errorCallback(jqXhr.responseJSON);
    }
  });
}

function buildMaterialMenuItems(clickedElementData) {
  const baseOptions = [
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
  ];

  const taggedPacts = clickedElementData.taggedPacts || [];
  const providerName = clickedElementData.providerName;
  const consumerName = clickedElementData.consumerName;
  const taggedPactsOptions = taggedPacts.map(taggedPact => {
    const taggedPactObject = JSON.parse(taggedPact);
    const pactTagName = taggedPactObject.tag;
    const taggedPactUrl = taggedPactObject.deletionUrl;
    return {
      type: "normal",
      text: `Delete pacts for ${pactTagName}...`,
      click: handleDeleteTagSelected({
        providerName,
        consumerName,
        pactTagName,
        deletionUrl: taggedPactUrl
      })
    };
  });

  return [...baseOptions, ...taggedPactsOptions];
}
