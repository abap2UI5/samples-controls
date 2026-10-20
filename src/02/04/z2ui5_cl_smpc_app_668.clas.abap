CLASS z2ui5_cl_smpc_app_668 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_668 IMPLEMENTATION.

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
                    )->a( n = `text`  v = `No columnsRatio (single column)`
                    )->a( n = `level` v = `H4`
                    )->a( n = `class` v = `sapUiSmallMarginBottom sapUiSmallMarginTop sapUiSmallMarginBegin`

                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMarginBeginEnd`

                    )->ele( n = `HeroBanner` ns = `f`
                        )->a( n = `headerText`   v = `Welcome back, Sarah`
                        )->a( n = `overlineText` v = `Monday, May 26, 2026`

                        )->ele( n = `actions` ns = `f`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://receipt`
                                )->a( n = `text` v = `Approve Invoices`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://shipping-status`
                                )->a( n = `text` v = `Track Deliveries`

                        )->end(
                        )->ele( n = `startContent` ns = `f`
                            )->tag( `Text`
                                )->a( n = `class` v = `heroBannerWhiteText`
                                )->a( n = `text`  v = `Here you can insert any additional information that may be relevant to the context. ` &&
                                                      `This section serves as a placeholder for content that can provide more in-depth ` &&
                                                      `explanations, supplementary data, or any other pertinent details that the reader might need.`

                        )->end(
                    )->end(
                )->end(

                )->tag( `Title`
                    )->a( n = `text`  v = `columnsRatio="Equal" (equal width columns)`
                    )->a( n = `level` v = `H4`
                    )->a( n = `class` v = `sapUiSmallMarginBottom sapUiMediumMarginTop sapUiSmallMarginBegin`

                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMarginBeginEnd`

                    )->ele( n = `HeroBanner` ns = `f`
                        )->a( n = `headerText`   v = `Hi, David`
                        )->a( n = `overlineText` v = `Monday, May 26, 2026`
                        )->a( n = `columnsRatio` v = `Equal`

                        )->ele( n = `startContent` ns = `f`
                            )->ele( n = `Card` ns = `f`
                                )->ele( n = `header` ns = `f`
                                    )->tag( n = `Header` ns = `card`
                                        )->a( n = `title`    v = `Leave Balance`
                                        )->a( n = `subtitle` v = `Days remaining`

                                )->end(
                                )->ele( n = `content` ns = `f`
                                    )->ele( `VBox`
                                        )->a( n = `class` v = `sapUiSmallMargin`

                                        )->tag( `Title`
                                            )->a( n = `text`  v = `18 of 30`
                                            )->a( n = `level` v = `H3`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(
                        )->ele( n = `endContent` ns = `f`
                            )->ele( n = `Card` ns = `f`
                                )->ele( n = `header` ns = `f`
                                    )->tag( n = `Header` ns = `card`
                                        )->a( n = `title`    v = `Next Payroll`
                                        )->a( n = `subtitle` v = `June 2026`

                                )->end(
                                )->ele( n = `content` ns = `f`
                                    )->ele( `VBox`
                                        )->a( n = `class` v = `sapUiSmallMargin`

                                        )->tag( `Title`
                                            )->a( n = `text`  v = `Jun 30`
                                            )->a( n = `level` v = `H3`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(
                    )->end(
                )->end(

                )->tag( `Title`
                    )->a( n = `text`  v = `columnsRatio="FirstWider" (start column twice as wide)`
                    )->a( n = `level` v = `H4`
                    )->a( n = `class` v = `sapUiSmallMarginBottom sapUiMediumMarginTop sapUiSmallMarginBegin`

                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMarginBeginEnd`

                    )->ele( n = `HeroBanner` ns = `f`
                        )->a( n = `headerText`   v = `Good Afternoon, Thomas`
                        )->a( n = `overlineText` v = `Monday, May 26, 2026`
                        )->a( n = `columnsRatio` v = `FirstWider`

                        )->ele( n = `startContent` ns = `f`
                            )->ele( n = `Card` ns = `f`
                                )->ele( n = `header` ns = `f`
                                    )->tag( n = `Header` ns = `card`
                                        )->a( n = `title`    v = `Sales Pipeline`
                                        )->a( n = `subtitle` v = `Q2 2026`

                                )->end(
                                )->ele( n = `content` ns = `f`
                                    )->ele( `VBox`
                                        )->a( n = `class` v = `sapUiSmallMargin`

                                        )->tag( `Title`
                                            )->a( n = `text`  v = `€4.2M`
                                            )->a( n = `level` v = `H3`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(
                        )->ele( n = `endContent` ns = `f`
                            )->ele( n = `Card` ns = `f`
                                )->ele( n = `header` ns = `f`
                                    )->tag( n = `Header` ns = `card`
                                        )->a( n = `title`    v = `Overdue Tasks`
                                        )->a( n = `subtitle` v = `Action needed`

                                )->end(
                                )->ele( n = `content` ns = `f`
                                    )->ele( `VBox`
                                        )->a( n = `class` v = `sapUiSmallMargin`

                                        )->tag( `Title`
                                            )->a( n = `text`  v = `3`
                                            )->a( n = `level` v = `H3` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
