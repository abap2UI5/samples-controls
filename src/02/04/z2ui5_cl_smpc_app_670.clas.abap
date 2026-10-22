" @keywords herobanner hero banner sap.f herobannerintegrationcard vbox button card
" @summary Demonstrates the use of sap.ui.integration.widgets.Card inside both the startContent (default slot) and endContent aggregations of the Hero Banner.
" @origin sap.f.sample.HeroBannerIntegrationCard - https://sdk.openui5.org/entity/sap.f.HeroBanner/sample/sap.f.sample.HeroBannerIntegrationCard (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_670 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_670 IMPLEMENTATION.

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
        )->a( n = `xmlns:w`      v = `sap.ui.integration.widgets`
        )->a( n = `height`       v = `100%`
        )->a( n = `displayBlock` v = `true`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            )->ele( `content`
                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMarginBeginEnd sapUiMediumMarginTop`

                    )->ele( n = `HeroBanner` ns = `f`
                        )->a( n = `headerText`   v = `Good Morning, John`
                        )->a( n = `overlineText` v = `Thursday, July 10, 2026`
                        )->a( n = `columnsRatio` v = `FirstWider`

                        )->ele( n = `actions` ns = `f`
                            )->tag( `Button`
                                )->a( n = `text` v = `Explore`
                                )->a( n = `type` v = `Emphasized`
                            )->tag( `Button`
                                )->a( n = `text` v = `Settings`

                        )->end(
                        " both Card manifests by URL, as in the original - absolutized to
                        " the OpenUI5 host, since the demo kit's relative test-resources
                        " path has no document root to resolve against here
                        )->ele( n = `startContent` ns = `f`
                            )->tag( n = `Card` ns = `w`
                                )->a( n = `manifest` v = `https://sdk.openui5.org/test-resources/sap/f/demokit/sample/HeroBannerIntegrationCard/startContentManifest.json`

                        )->end(
                        )->ele( n = `endContent` ns = `f`
                            )->tag( n = `Card` ns = `w`
                                )->a( n = `manifest` v = `https://sdk.openui5.org/test-resources/sap/f/demokit/sample/HeroBannerIntegrationCard/endContentManifest.json` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
