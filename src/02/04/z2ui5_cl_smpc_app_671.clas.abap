" @keywords herobanner hero banner sap.f herobannerusecases html title vbox button text card header
" @summary A collection of common Hero Banner use cases: header actions only, content with actions, actions below header, and header at bottom.
" @origin sap.f.sample.HeroBannerUseCases - https://sdk.openui5.org/entity/sap.f.HeroBanner/sample/sap.f.sample.HeroBannerUseCases (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_671 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_671 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`        v = `sap.m`
        )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
        )->a( n = `xmlns:f`      v = `sap.f`
        )->a( n = `xmlns:card`   v = `sap.f.cards`
        )->a( n = `xmlns:core`   v = `sap.ui.core`
        )->a( n = `height`       v = `100%`
        )->a( n = `displayBlock` v = `true`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            )->ele( `content`
                " the sample's main.css, injected via a core:HTML content attribute
                " (see CAPABILITIES.md) - literal braces escaped in a backtick literal
                )->tag( n = `HTML` ns = `core`
                    )->a( n = `content` v = `<style>.heroBannerWhiteText\{color:var(--sapTextInvertedColor)\}</style>`

                )->tag( `Title`
                    )->a( n = `text`  v = `Header Actions Only`
                    )->a( n = `level` v = `H4`
                    )->a( n = `class` v = `sapUiSmallMarginBottom sapUiSmallMarginTop sapUiSmallMarginBegin`

                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMarginBeginEnd`

                    )->ele( n = `HeroBanner` ns = `f`
                        )->a( n = `headerText`   v = `Welcome, Lisa`
                        )->a( n = `overlineText` v = `Tuesday, May 27, 2026`

                        )->ele( n = `actions` ns = `f`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://action-settings`
                                )->a( n = `text` v = `Settings`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://activity-individual`
                                )->a( n = `text` v = `Activity Log`

                        )->end(
                    )->end(
                )->end(

                )->tag( `Title`
                    )->a( n = `text`  v = `Content with Actions`
                    )->a( n = `level` v = `H4`
                    )->a( n = `class` v = `sapUiSmallMarginBottom sapUiMediumMarginTop sapUiSmallMarginBegin`

                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMarginBeginEnd`

                    )->ele( n = `HeroBanner` ns = `f`
                        )->a( n = `headerText`   v = `Good Morning, Robert`
                        )->a( n = `overlineText` v = `Tuesday, May 27, 2026`

                        )->ele( n = `actions` ns = `f`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://task`
                                )->a( n = `text` v = `Review Approvals`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://add-document`
                                )->a( n = `text` v = `Create Report`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://collaborate`
                                )->a( n = `text` v = `Team Overview`

                        )->end(
                        )->ele( n = `startContent` ns = `f`
                            )->tag( `Text`
                                )->a( n = `class` v = `heroBannerWhiteText`
                                )->a( n = `text`  v = `You have 3 pending approvals and 12 new notifications since your last visit. ` &&
                                                      `Review your tasks below or use the quick actions to get started.`

                        )->end(
                    )->end(
                )->end(

                )->tag( `Title`
                    )->a( n = `text`  v = `Actions Below Header (actionsPlacement="BottomStart")`
                    )->a( n = `level` v = `H4`
                    )->a( n = `class` v = `sapUiSmallMarginBottom sapUiMediumMarginTop sapUiSmallMarginBegin`

                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMarginBeginEnd`

                    )->ele( n = `HeroBanner` ns = `f`
                        )->a( n = `headerText`       v = `Hello, Emma`
                        )->a( n = `overlineText`     v = `Wednesday, May 28, 2026`
                        )->a( n = `actionsPlacement` v = `BottomStart`
                        )->a( n = `columnsRatio`     v = `Equal`

                        )->ele( n = `actions` ns = `f`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://create`
                                )->a( n = `text` v = `New Request`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://add-document`
                                )->a( n = `text` v = `Create Report`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://collaborate`
                                )->a( n = `text` v = `Team Overview`

                        )->end(
                        )->ele( n = `endContent` ns = `f`
                            )->ele( n = `Card` ns = `f`
                                )->a( n = `width` v = `100%`

                                )->ele( n = `header` ns = `f`
                                    )->tag( n = `Header` ns = `card`
                                        )->a( n = `title`    v = `Open Tickets`
                                        )->a( n = `subtitle` v = `Support`

                                )->end(
                                )->ele( n = `content` ns = `f`
                                    )->ele( `VBox`
                                        )->a( n = `class` v = `sapUiSmallMargin`

                                        )->tag( `Title`
                                            )->a( n = `text`  v = `42`
                                            )->a( n = `level` v = `H3`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(
                    )->end(
                )->end(

                )->tag( `Title`
                    )->a( n = `text`  v = `Header at Bottom (headerBlockPlacement="Bottom")`
                    )->a( n = `level` v = `H4`
                    )->a( n = `class` v = `sapUiSmallMarginBottom sapUiMediumMarginTop sapUiSmallMarginBegin`

                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMarginBeginEnd sapUiMediumMarginBottom`

                    )->ele( n = `HeroBanner` ns = `f`
                        )->a( n = `headerText`           v = `Good Afternoon, James`
                        )->a( n = `overlineText`         v = `Wednesday, May 28, 2026`
                        )->a( n = `columnsRatio`         v = `FirstWider`
                        )->a( n = `headerBlockPlacement` v = `Bottom`

                        )->ele( n = `actions` ns = `f`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://cart`
                                )->a( n = `text` v = `Orders`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://task`
                                )->a( n = `text` v = `Tasks`

                        )->end(
                        )->ele( n = `endContent` ns = `f`
                            )->ele( n = `Card` ns = `f`
                                )->a( n = `width` v = `100%`

                                )->ele( n = `header` ns = `f`
                                    )->tag( n = `Header` ns = `card`
                                        )->a( n = `title`    v = `Revenue YTD`
                                        )->a( n = `subtitle` v = `Q2 2026`

                                )->end(
                                )->ele( n = `content` ns = `f`
                                    )->ele( `VBox`
                                        )->a( n = `class` v = `sapUiSmallMargin`

                                        )->tag( `Title`
                                            )->a( n = `text`  v = `€4.2M`
                                            )->a( n = `level` v = `H3` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
