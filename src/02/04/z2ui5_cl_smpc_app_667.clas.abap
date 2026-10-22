" @keywords herobanner hero banner sap.f herobannerbasic vbox
" @summary A basic Hero Banner with a header text and overline text.
" @origin sap.f.sample.HeroBannerBasic - https://sdk.openui5.org/entity/sap.f.HeroBanner/sample/sap.f.sample.HeroBannerBasic (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_667 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_667 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`        v = `sap.m`
        )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
        )->a( n = `xmlns:f`      v = `sap.f`
        )->a( n = `height`       v = `100%`
        )->a( n = `displayBlock` v = `true`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            )->ele( `content`
                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMarginBeginEnd sapUiMediumMarginTop`

                    )->tag( n = `HeroBanner` ns = `f`
                        )->a( n = `headerText`   v = `Good Morning, Anna`
                        )->a( n = `overlineText` v = `Monday, May 26, 2026` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
