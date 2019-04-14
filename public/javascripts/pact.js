$(document).ready(function() {
  $(".pact-badge").click(function() {
    $(".pact-badge-markdown").toggle();
  });

  $(".more-options")
    .materialMenu("init", {
      position: "overlay",
      animationSpeed: 1,
      items: [
        // {
        //   type: "normal",
        //   text: "View in API Browser",
        //   click: function(openMenuElement) {
        //     window.location.href = openMenuElement.data().apiBrowserUrl;
        //   }
        // },
        // {
        //   type: "normal",
        //   text: "View Matrix",
        //   click: function(openMenuElement) {
        //     window.location.href = openMenuElement.data().matrixUrl;
        //   }
        // },
        {
          type: "normal",
          text: "Delete ...",
          click: function(openMenuElement) {
            promptToDeleteResource(openMenuElement.data().pactUrl, createDeletionConfirmationText(openMenuElement.data()))
          }
        }
      ]
    })
    .click(function() {
      $(this).materialMenu("open");
    });
});

function createDeletionConfirmationText(data) {
  return `Do you wish to delete the pact for version ${data.consumerVersionNumber} of ${data.consumerName}?`;
}


function confirmDeleteResource(
  confirmationText,
  confirmCallbak,
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
        action: confirmCallbak
      },
      cancel: cancelCallback
    }
  });
}

function promptToDeleteResource(deletionUrl, confirmationText) {
  const cancel = function() {};
  const confirm = function() {
    deleteResource(
      deletionUrl,
      handleDeletionSuccess,
      handleDeletionFailure
    );
  };

  confirmDeleteResource(
    confirmationText,
    confirm,
    cancel
  );
}

function handleDeletionSuccess(responseBody) {
  if(responseBody._links['pb:latest-pact-version']) {
    $.confirm({
      title: "Pact deleted",
      content: "Where to next?",
      buttons: {
        latest: {
          text: "Latest pact",
          keys: ["enter", "shift"],
          action: function() { window.location.href = responseBody._links['pb:latest-pact-version'].href }
        },
        home: {
          text: "Home",
          action: function() { window.location.href = "/"; }
        }
      }
    });

  } else {
    window.location.href = "/";
  }
}

function handleDeletionFailure(response) {
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

function deleteResource(url, successCallback, errorCallback) {
  $.ajax({
    url: url,
    dataType: "json",
    type: "delete",
    accepts: {
      text: "application/hal+json"
    },
    success: function(data, textStatus, jQxhr) {
      successCallback(data);
    },
    error: function(jqXhr, textStatus, errorThrown) {
      errorCallback(jqXhr.responseJSON);
    }
  });
}
