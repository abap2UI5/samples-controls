" @keywords illustratedmessage illustrated message sap.m illustratedmessagesessiontimeout vbox label stepinput button dialog
" @summary All applications that require user sign-in should employ a mechanism for automating user sign-out. When the inactivity is about to reach that threshold, a session timeout dialog appears automatically to inform the user.
" @origin sap.m.sample.IllustratedMessageSessionTimeout - https://sdk.openui5.org/entity/sap.m.IllustratedMessage/sample/sap.m.sample.IllustratedMessageSessionTimeout (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_638 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA bisexpiring TYPE abap_bool.
    DATA isecondsleft TYPE i.
    " original: the StepInput's literal value=3, read via byId('expirationInput').getValue()
    DATA expiration TYPE i VALUE 3.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    " the controller's iSeconds counter and its clearInterval guard
    DATA iseconds TYPE i.
    DATA check_counting TYPE abap_bool.

    METHODS view_display.
    METHODS on_event.
    METHODS popup_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_638 IMPLEMENTATION.

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
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `height`    v = `100%`

        )->ele( `VBox`
            )->ele( `VBox`
                )->a( n = `class` v = `sapUiSmallMargin`

                )->tag( `Label`
                    )->a( n = `text` v = `Seconds until session expiration`
                )->tag( `StepInput`
                    )->a( n = `id`    v = `expirationInput`
                    )->a( n = `value` v = client->_bind( expiration )
                    )->a( n = `min`   v = `2`
                    )->a( n = `max`   v = `9`
                    )->a( n = `width` v = `3rem`

            )->end(

            )->tag( `Button`
                )->a( n = `press` v = client->_event( `OPEN_DIALOG` )
                )->a( n = `text`  v = `Open Dialog`
                )->a( n = `class` v = `sapUiSmallMarginBegin` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `OPEN_DIALOG`.
        " original onDialogOpen: open, then _startCounter / _onCounterStart
        iseconds = expiration.
        bisexpiring = abap_true.
        isecondsleft = iseconds.
        iseconds = iseconds - 1.
        check_counting = abap_true.
        popup_display( ).
        " the original's setInterval( 1000 ) - one framework timer per tick, re-armed below
        client->follow_up_action( val   = client->cs_event-start_timer
                                  t_arg = VALUE #( ( `COUNTER_TICK` ) ( `1000` ) ) ).

      WHEN `COUNTER_TICK`.
        " original _decrementCounter
        IF check_counting = abap_false.
          RETURN.
        ENDIF.
        isecondsleft = iseconds.
        IF iseconds = 0.
          check_counting = abap_false.
          bisexpiring = abap_false.
          RETURN.
        ENDIF.
        iseconds = iseconds - 1.
        client->follow_up_action( val   = client->cs_event-start_timer
                                  t_arg = VALUE #( ( `COUNTER_TICK` ) ( `1000` ) ) ).

      WHEN `DIALOG_CLOSE` OR `SIGN_IN`.
        " original onDialogClose / onSignIn: close the dialog and stop the counter
        check_counting = abap_false.
        client->popup_destroy( ).

    ENDCASE.

  ENDMETHOD.


  METHOD popup_display.

    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

    " i18n texts folded to their i18n.properties literals - see the sidecar
    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Dialog`
            )->a( n = `title`             v = `Session Info`
            )->a( n = `contentWidth`      v = `20rem`
            )->a( n = `verticalScrolling` v = `false`

            )->ele( `buttons`
                )->tag( `Button`
                    )->a( n = `visible` v = client->_bind( bisexpiring )
                    )->a( n = `text`    v = `Continue Working`
                    )->a( n = `press`   v = client->_event( `DIALOG_CLOSE` )
                    )->a( n = `type`    v = `Emphasized`
                )->tag( `Button`
                    )->a( n = `visible` v = |\{= !${ client->_bind( bisexpiring ) } \}|
                    )->a( n = `text`    v = `Sign In`
                    )->a( n = `press`   v = client->_event( `SIGN_IN` )
                    )->a( n = `type`    v = `Emphasized`
                )->tag( `Button`
                    )->a( n = `visible` v = |\{= !${ client->_bind( bisexpiring ) } \}|
                    )->a( n = `text`    v = `Close`
                    )->a( n = `press`   v = client->_event( `DIALOG_CLOSE` )

            )->end(

            " the tnt illustration set is registered by the original Component (IllustrationPool) - see the sidecar
            )->tag( `IllustratedMessage`
                )->a( n = `title`            v = |\{= ${ client->_bind( bisexpiring ) } ? 'Your session will expire soon.' : 'Your session has expired.' \}|
                )->a( n = `description`      v = |\{= ${ client->_bind( bisexpiring ) } ? | &&
                                                 |'You will be signed out in ' + ${ client->_bind( isecondsleft ) } + ' seconds.' : | &&
                                                 |'Sign in to pick up where you left off.' \}|
                )->a( n = `illustrationType` v = |\{= ${ client->_bind( bisexpiring ) } ? 'tnt-SessionExpiring' : 'tnt-SessionExpired' \}| ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    bisexpiring = abap_true.
    isecondsleft = 99.

  ENDMETHOD.

ENDCLASS.
