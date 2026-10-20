CLASS z2ui5_cl_smpc_app_669 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_669 IMPLEMENTATION.

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
        )->a( n = `height`       v = `100%`
        )->a( n = `displayBlock` v = `true`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            )->ele( `content`
                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMarginBeginEnd sapUiMediumMarginTop`

                    )->ele( n = `HeroBanner` ns = `f`
                        )->a( n = `headerText`           v = `Good Morning, Anna`
                        )->a( n = `overlineText`         v = `Monday, May 26, 2026`
                        )->a( n = `columnsRatio`         v = `Equal`
                        )->a( n = `actionsPlacement`     v = `BottomStart`
                        )->a( n = `headerBlockPlacement` v = `Bottom`

                        )->ele( n = `actions` ns = `f`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://create`
                                )->a( n = `text` v = `New Request`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://document`
                                )->a( n = `text` v = `Create Report`
                            )->tag( `Button`
                                )->a( n = `icon` v = `sap-icon://email`
                                )->a( n = `text` v = `Send Message`

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
                                            )->a( n = `level` v = `H3` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
