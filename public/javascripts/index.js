$(document).ready(function() {
  $(".integration-settings")
    .materialMenu("init", {
      position: "overlay",
      animationSpeed: 1,
      items: [
        {
          type: "normal",
          text: "Delete all pact versions...",
          click: function(e) {
            promptToDeletePactVersions($(e).data(), $(e).closest("tr"));
          }
        }
      ]
    })
    .click(function() {
      $(this).materialMenu("open");
    });
});

function promptToDeletePactVersions(rowData, row) {
  const agree = confirm(
    `This will delete all versions of the pact between ${
      rowData.consumerName
    } and ${rowData.providerName}. It will keep ${rowData.consumerName} and ${
      rowData.providerName
    }, and all other data related to them (webhooks, application versions, and tags). Do you wish to continue?`
  );
  if (agree) {
    deletePactVersions(
      rowData.pactVersionsUrl,
      function() {
        handleDeletionSuccess(row);
      },
      handleDeletionFailure
    );
  }
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

function handleDeletionFailure(response) {
  let errorMessage = null;

  if (response.error && response.error.message && response.error.reference) {
    errorMessage =
      "Could not delete resources due to error: " +
      response.error.message +
      "\nError reference: " +
      response.error.reference;
  } else {
    errorMessage =
      "Could not delete resources due to error: " + JSON.stringify(response);
  }

  alert(errorMessage);
}

function deletePactVersions(url, successCallback, errorCallback) {
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
