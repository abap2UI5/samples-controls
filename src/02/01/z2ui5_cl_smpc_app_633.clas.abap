" @keywords illustratedmessage illustrated message sap.m illustratedmessageindialog button dialog
" @summary IllustratedMessage as content of sap.m.Dialog.
" @origin sap.m.sample.IllustratedMessageInDialog - https://sdk.openui5.org/entity/sap.m.IllustratedMessage/sample/sap.m.sample.IllustratedMessageInDialog (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_633 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS popup_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_633 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `height`    v = `100%`

        )->tag( `Button`
            )->a( n = `press` v = client->_event( `OPEN_DIALOG` )
            )->a( n = `text`  v = `Open Dialog`
            )->a( n = `class` v = `sapUiSmallMarginBegin sapUiSmallMarginTop` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `OPEN_DIALOG`.
      popup_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD popup_display.

    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Dialog`
            )->a( n = `title`             v = `Error`
            )->a( n = `contentWidth`      v = `20rem`
            )->a( n = `verticalScrolling` v = `false`
            )->a( n = `state`             v = `Error`

            )->ele( `buttons`
                " original onDialogClose - closed on the client, no round-trip
                )->tag( `Button`
                    )->a( n = `text`  v = `Close`
                    )->a( n = `press` v = client->follow_up_action( client->cs_event-popup_close )

            )->end(

            )->tag( `IllustratedMessage`
                )->a( n = `illustrationType` v = `sapIllus-UnableToLoad` ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
