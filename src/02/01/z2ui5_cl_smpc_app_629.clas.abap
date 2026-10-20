CLASS z2ui5_cl_smpc_app_629 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_629 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `height`    v = `100%`

        )->ele( n = `ResponsiveSplitter` ns = `l`
            )->ele( n = `PaneContainer` ns = `l`
                )->a( n = `orientation` v = `Vertical`

                )->ele( n = `SplitPane` ns = `l`
                    )->ele( n = `layoutData` ns = `l`
                        )->tag( n = `SplitterLayoutData` ns = `l`
                            )->a( n = `size` v = `70%`

                    )->end(

                    )->ele( `IllustratedMessage`
                        )->a( n = `enableVerticalResponsiveness` v = `true`
                        )->a( n = `illustrationType`             v = `sapIllus-NoActivities`

                        )->ele( `additionalContent`
                            )->tag( `Button`
                                )->a( n = `text` v = `Add Activity`

                        )->end(
                    )->end(
                )->end(

                )->ele( n = `SplitPane` ns = `l`
                    )->tag( `VBox` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
