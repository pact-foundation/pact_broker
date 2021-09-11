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

function createPactTagOrBranchDeletionConfirmationText({
  providerName,
  consumerName,
  refName,
  scope
}) {
  return `This will delete the pacts for provider ${providerName} and all versions of ${
    consumerName
  } ${scope} ${refName}. Do you wish to continue?`;
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

function handleDeleteTagOrBranchSelected({
  providerName,
  consumerName,
  refName,
  deletionUrl,
  scope
}) {
  return function(clickedElement) {
    const tr = $(clickedElement).closest("tr");
    const confirmationText = createPactTagOrBranchDeletionConfirmationText({
      providerName,
      consumerName,
      refName,
      scope
    });
    handleDeleteResourcesSelected(
      tr,
      deletionUrl,
      confirmationText,
      refName
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
  const cancelled = function() {
    unHighlightRows(row);
  };
  const confirmed = function() {
    deleteResources(
      deletionUrl,
      handleDeletionSuccess,
      function(response) {
        handleDeletionFailure(row, response);
      }
    );
  };


  highlightRowsToBeDeleted(row);

  confirmDeleteResources(confirmationText, confirmed, cancelled);
}

function refreshPage() {
  const url = new URL(window.location);
  window.location = url.toString();
}

function handleDeletionSuccess() {
  return refreshPage();
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
  const providerName = clickedElementData.providerName;
  const consumerName = clickedElementData.consumerName;

  if (clickedElementData.view === "branch" || clickedElementData.view === "all") {
    return (clickedElementData.pactBranches || []).map(branch => {
      const refName = branch.name;
      const deletionUrl = branch.deletionUrl;
      return {
        type: "normal",
        text: `Delete pacts from branch ${refName}...`,
        click: handleDeleteTagOrBranchSelected({
          providerName,
          consumerName,
          refName,
          deletionUrl: deletionUrl,
          scope: "for branch"
        })
      };
    });
  } else if (clickedElementData.view === "tag" || clickedElementData.view === "all") {
    return (clickedElementData.pactTags || []).map(tag => {
    const refName = tag.name;
    const deletionUrl = tag.deletionUrl;
      return {
        type: "normal",
        text: `Delete pacts for tag ${refName}...`,
        click: handleDeleteTagOrBranchSelected({
          providerName,
          consumerName,
          refName,
          deletionUrl,
          scope: "with tag"
        })
      };
    });
  } else if (clickedElementData.index) {
    return [
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
  } else {
    return []
  }
}
