(function ($) {
    var id = 0;
    var menus = {};

    $.fn.materialMenu = function (action, settings) {
        var settings = $.extend({
            animationSpeed: 250,
            position: "",
            items: []
        }, settings);

        return this.each(function (item) {
            var parent = $(this);
            if (action === "init") {
                parent.attr('id', getNextId());
                var menu = getMenuForParent(parent);
                menu.element = $('<div class="material-menu"><ul></ul></div>');
                menu.parent = parent;
                menu.settings = settings;
                menu.items = [];

                settings.items.forEach(function (item) {
                    var item = $.extend({
                        text: "",
                        type: "normal",
                        radioGroup: "default",
                        click: function () { }
                    }, item);
                    if (item.type === 'toggle') {
                        var elStr = "<li class='check" + (item.checked ? "" : " unchecked") + "'></li>";
                        var itemElement = $(elStr)
                            .append("<i class='material-icons md-24'>check</i>")
                            .append("<span>" + item.text + "</span>")
                            .click(function () {
                                if (item.checked) {
                                    item.element.addClass('unchecked');
                                } else {
                                    item.element.removeClass('unchecked');
                                }
                                item.checked = !item.checked;
                                item.click(menu.parent, item.checked);
                                closeMenu(menu);
                            });
                    } else if (item.type === 'radio') {
                        var elStr = "<li class='check" + (item.checked ? "" : " unchecked") + "'></li>";
                        var itemElement = $(elStr)
                            .append("<i class='material-icons md-24'>check</i>")
                            .append("<span>" + item.text + "</span>")
                            .click(function () {
                                menu.items.forEach(function (otherItem) {
                                    if (otherItem.radioGroup === item.radioGroup) {
                                        if (otherItem == item) {
                                            item.element.removeClass('unchecked');
                                            otherItem.checked = false;
                                        } else {
                                            otherItem.element.addClass('unchecked');
                                            otherItem.checked = false;
                                        }
                                    }
                                });
                                item.click(menu.parent, item.checked);
                                closeMenu(menu);
                            });
                    } else if (item.type === 'divider') {
                        var itemElement = $("<li class='divider'></li>");
                    } else if (item.type === 'label') {
                        var itemElement = $("<li class='label'></li>")
                            .html(item.text);
                    } else if (item.type === 'submenu') {
                        var itemElement = $("<li></li>")
                            .append("<span>" + item.text + "</span>")
                            .append('<div class="icon-wrapper sm-right"><i class="material-icons md-24 sm-rotate-90">arrow_drop_up</i></div>')
                            .click(function () {
                                item.click(menu.parent);
                                closeMenu(menu);
                            });
                    } else if (item.type === 'normal') {
                        var itemElement = $("<li></li>")
                            .html(item.text)
                            .click(function () {
                                item.click(menu.parent);
                                closeMenu(menu);
                            });
                    } else {
                        console.log("Menu item with invalid type, type was: " + item.type);
                        return;
                    }
                    itemElement.attr('id', getNextId());
                    item.element = itemElement;
                    menu.element.children('ul').append(itemElement);
                    menu.items.push(item);
                });
                menu.element.hide();
                $('body').append(menu.element);

                return this;
            }

            if (action === 'open') {
                var menu = getMenuForParent(parent);
                if (menu.open) {
                    return;
                }
                openMenu(menu);
                return this;
            }

            if (action === 'close') {
                var menu = getMenuForParent(parent);
                if (!menu.open) {
                    return;
                }
                closeMenu(menu);
                return this;
            }
        });
    };

    function openMenu(menu) {
        menu.open = true;
        updatePos(menu);

        menu.element.css('opacity', 0)
          .slideDown(menu.settings.animationSpeed)
          .animate(
            { opacity: 1 },
            { queue: false, duration: 'fast' }
          );

        $(document).on('mousedown', function (event) {
            if (!$(event.target).closest(menu.element).length) {
                closeMenu(menu);
            }
        });
    }

    function closeMenu(menu) {
        menu.element.fadeOut(menu.settings.animationSpeed, function () {
            menu.open = false;
        });
    }

    function updatePos(menu) {
        // position the div, according to it's parent using the worlds most hacky thing ever
        var offset = $("#" + menu.parent.attr('id')).offset();
        var left = offset.left;
        var top = offset.top + menu.parent.outerHeight();

        // If the menu is greater than 75% of the screen size, it should scroll
        menu.element.height('auto'); // so the height calculation works correctly
        var menuHeight = menu.element.outerHeight();
        var windowHeight = $(window).height();
        if (menuHeight > windowHeight * 0.75) {
            menu.element.height(windowHeight * 0.75);
            menuHeight = menu.element.outerHeight();
        }

        // Offset top, if the menu would appear below the screen (with 5px margin)
        var distanceFromBottom = windowHeight - menuHeight - top - 5;
        if (distanceFromBottom < 0) {
            // Need to adjust the menu, to make it fit the screen bounds
            if (distanceFromBottom > -menuHeight / 2) {
                menu.element.height(menu.element.height() + distanceFromBottom);

                // If doing overlay positioning, subtract height
                if (menu.settings.position.indexOf('overlay') >= 0) {
                    top -= menu.parent.outerHeight();
                }
            } else {
                top -= menuHeight;
                // If NOT doing overlay positioning, subtract height
                if (menu.settings.position.indexOf('overlay') == -1) {
                    top -= menu.parent.outerHeight();
                }
            }
        }

        // Calculate width so we can ensure the menu is not displayed off of the right hand side of the screen
        var menuWidth = menu.element.outerWidth()
        var windowWidth = $(window).width();
        var distanceFromRight = windowWidth - menuWidth - left - 5;
        if (distanceFromRight < 0) {
            left -= menu.element.outerWidth() - menu.parent.outerWidth();
        }

        menu.element.css({ top: top, left: left });
    }

    function getMenuForParent(parent) {
        var id = parent.attr('id');
        if (menus[id] == undefined) {
            menus[id] = {};
        }
        return menus[id];
    }

    function getNextId() {
        return 'sm-' + id++;
    }

    // Should rethink how this works, but will do for now
    $(document).ready(function () {
        var items = $('sm-title');
        for (var i=0; i<items.length; i++) {
            var element = items.eq(i);
            var newElement = $('<span></span>')
                .text(element.text())
                .addClass('sm-text sm-font-title')
                .attr('id', getNextId());
            element.replaceWith(newElement);
        }

        items = $('sm-toolbar');
        for (var i=0; i<items.length; i++) {
            var element = items.eq(i);
            var newElement = $('<div></div>')
                .html(element.html())
                .addClass('sm-toolbar sm-primary-500')
                .attr('id', getNextId());

            var toolbarItems = newElement.find('sm-item');
            console.log(toolbarItems);
            for (var j=0; j<toolbarItems.length; j++) {
                var item = toolbarItems.eq(j);
                var newItem = $('<span></span>')
                    .append($('<i></i>')
                        .text(item.text())
                        .addClass('sm-icon material-icons md-24'))
                    .attr('id', getNextId());
                if (item.attr('left') != undefined) {
                    newItem.addClass('sm-left');
                } else if (item.attr('right') != undefined) {
                    newItem.addClass('sm-right');
                }
                item.replaceWith(newItem);
            }

            element.replaceWith(newElement);
        }
    });
}(jQuery));