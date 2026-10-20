" @keywords avatar sap.m avataractivestate popover list standardlistitem messagestrip
" @summary This sample demonstrates toggling of Avatar Active state, when a User menu is opened/closed.
" @origin sap.m.sample.AvatarActiveState - https://sdk.openui5.org/entity/sap.m.Avatar/sample/sap.m.sample.AvatarActiveState (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_625 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA woman01 TYPE string.
    DATA active  TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_625 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `height`    v = `100%`

        " onInit's Fragment.load( Popover ) + addDependent, declared in the view's dependents instead;
        " the UserMenu fragment the Popover pulls in via core:Fragment is inlined
        )->ele( n = `dependents` ns = `mvc`
            )->ele( `Popover`
                )->a( n = `id`             v = `userMenu`
                )->a( n = `title`          v = `User Menu`
                )->a( n = `titleAlignment` v = `Center`
                )->a( n = `placement`      v = `Bottom`
                )->a( n = `afterClose`     v = client->_event( `POPOVER_CLOSE` )

                )->ele( `List`
                    )->ele( `items`
                        )->tag( `StandardListItem`
                            )->a( n = `icon`  v = `sap-icon://customer-history`
                            )->a( n = `title` v = `Recent Activities`
                            )->a( n = `type`  v = `Active`
                            )->a( n = `press` v = client->_event( `LIST_ITEM_PRESS` )
                        )->tag( `StandardListItem`
                            )->a( n = `icon`  v = `sap-icon://activity-individual`
                            )->a( n = `title` v = `Frequently Used`
                            )->a( n = `type`  v = `Active`
                            )->a( n = `press` v = client->_event( `LIST_ITEM_PRESS` )
                        )->tag( `StandardListItem`
                            )->a( n = `icon`  v = `sap-icon://sys-find`
                            )->a( n = `title` v = `App Finder`
                            )->a( n = `type`  v = `Active`
                            )->a( n = `press` v = client->_event( `LIST_ITEM_PRESS` )
                        )->tag( `StandardListItem`
                            )->a( n = `icon`  v = `sap-icon://action-settings`
                            )->a( n = `title` v = `Settings`
                            )->a( n = `type`  v = `Active`
                            )->a( n = `press` v = client->_event( `LIST_ITEM_PRESS` )
                        )->tag( `StandardListItem`
                            )->a( n = `icon`  v = `sap-icon://edit`
                            )->a( n = `title` v = `Edit Home Page`
                            )->a( n = `type`  v = `Active`
                            )->a( n = `press` v = client->_event( `LIST_ITEM_PRESS` )
                        )->tag( `StandardListItem`
                            )->a( n = `icon`  v = `sap-icon://email`
                            )->a( n = `title` v = `Contact Support`
                            )->a( n = `type`  v = `Active`
                            )->a( n = `press` v = client->_event( `LIST_ITEM_PRESS` )
                        )->tag( `StandardListItem`
                            )->a( n = `icon`  v = `sap-icon://hint`
                            )->a( n = `title` v = `About`
                            )->a( n = `type`  v = `Active`
                            )->a( n = `press` v = client->_event( `LIST_ITEM_PRESS` )
                        )->tag( `StandardListItem`
                            )->a( n = `icon`  v = `sap-icon://log`
                            )->a( n = `title` v = `Sign Out`
                            )->a( n = `type`  v = `Active`
                            )->a( n = `press` v = client->_event( `LIST_ITEM_PRESS` )

                    )->end(
                )->end(
            )->end(
        )->end(

        )->tag( `MessageStrip`
            )->a( n = `text`            v = `Active state of Avatar is set, when the user clicks on the Avatar and the Popover menu is opened. ` &&
                                            `When the menu is closed, Active state is removed.`
            )->a( n = `showIcon`        v = `false`
            )->a( n = `showCloseButton` v = `false`
            )->a( n = `class`           v = `sapUiTinyMargin`
        " the controller's setActive( ) becomes the two-way bound active property
        )->tag( `Avatar`
            )->a( n = `id`          v = `myAvatar`
            )->a( n = `src`         v = client->_bind( woman01 )
            )->a( n = `displaySize` v = `L`
            )->a( n = `showBorder`  v = `true`
            )->a( n = `class`       v = `sapUiTinyMargin`
            )->a( n = `active`      v = client->_bind( active )
            )->a( n = `press`       v = client->_event( `AVATAR_PRESS` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).
      WHEN `AVATAR_PRESS`.
        " onPress: toggle the active state, close the menu if it was active, else open it by the Avatar
        IF active = abap_true.
          active = abap_false.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = VALUE #( ( `userMenu` ) ( `close` ) ) ).
        ELSE.
          active = abap_true.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = VALUE #( ( `userMenu` ) ( `openBy` ) ( `myAvatar` ) ) ).
        ENDIF.
      WHEN `POPOVER_CLOSE`.
        active = abap_false.
      WHEN `LIST_ITEM_PRESS`.
        active = abap_false.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `userMenu` ) ( `close` ) ) ).
    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " onInit's JSONModel - sap.ui.require.toUrl( 'sap/m/images/...' ), absolutized to the OpenUI5 host
    woman01 = `https://sdk.openui5.org/test-resources/sap/m/images/Woman_avatar_01.png`.

  ENDMETHOD.

ENDCLASS.
