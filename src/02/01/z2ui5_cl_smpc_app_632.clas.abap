CLASS z2ui5_cl_smpc_app_632 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_632 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:f`    v = `sap.f`
        )->a( n = `xmlns:card` v = `sap.f.cards`
        )->a( n = `height`     v = `100%`

        )->ele( n = `Card` ns = `f`
            )->a( n = `width` v = `300px`
            )->a( n = `class` v = `sapUiSmallMarginBegin sapUiSmallMarginTop`

            )->ele( n = `header` ns = `f`
                )->tag( n = `Header` ns = `card`
                    )->a( n = `title` v = `Inbox`

            )->end(
            )->ele( n = `content` ns = `f`
                )->tag( `IllustratedMessage`
                    )->a( n = `illustrationType` v = `sapIllus-NoMail` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
