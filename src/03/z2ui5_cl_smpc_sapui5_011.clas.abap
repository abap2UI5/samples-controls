" @keywords barcodescannerbutton shell simpleform label input
" @summary sap.ndc.BarcodeScannerButton expressed in abap2UI5 - a SAPUI5-only control, so the demo kit original is outside OpenUI5 and this is orientation rather than a 1:1 port.
" @origin sap.ndc.BarcodeScannerButton - https://ui5.sap.com/#/entity/sap.ndc.BarcodeScannerButton (status: collection - SAPUI5-only, hand-written, not a port)
"! <p class="shorttext">sap.ndc - BarcodeScannerButton</p>
"!
"! SAPUI5-only control: it ships with SAPUI5, not with OpenUI5, so there is no
"! demo kit original in this repo's sample universe and no 1:1 port (AGENTS section 3).
"! Collected here as orientation - how the control is expressed in abap2UI5.
"!
"! SAPUI5 demo kit: https://ui5.sap.com/#/entity/sap.ndc.BarcodeScannerButton
CLASS z2ui5_cl_smpc_sapui5_011 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA scan_input TYPE string.
    DATA scan_type  TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.

CLASS z2ui5_cl_smpc_sapui5_011 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( `ON_SCAN_SUCCESS` ).
      " get_event_arg( n ) answers empty for an argument the frontend did
      " not send; a table expression on t_event_arg would dump instead
      scan_input = client->get_event_arg( ).
      scan_type  = client->get_event_arg( 2 ).
      client->message_toast_display( |Scanned { scan_input } ({ scan_type })| ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `displayBlock` v = `true`
        )->a( n = `height`       v = `100%`
        )->a( n = `xmlns`        v = `sap.m`
        )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
        )->a( n = `xmlns:form`   v = `sap.ui.layout.form`
        )->a( n = `xmlns:ndc`    v = `sap.ndc`

        )->ele( `Shell`
            )->ele( `Page`
                )->a( n = `title`          v = `abap2UI5 - sap.ndc - BarcodeScannerButton`
                )->a( n = `navButtonPress` v = client->_event_nav_app_leave( )
                )->a( n = `showNavButton`  b = client->check_app_prev_stack( )
                )->a( n = `showHeader`     b = xsdbool( client->get( )-check_launchpad_active = abap_false )

                )->ele( n = `SimpleForm` ns = `form`
                    )->a( n = `title`    v = `Information`
                    )->a( n = `editable` b = abap_true

                    )->ele( n = `content` ns = `form`
                        )->tag( `Label`
                            )->a( n = `text` v = `Scanned text`
                        )->tag( `Input`
                            )->a( n = `value` v = client->_bind( scan_input )
                        )->tag( `Label`
                            )->a( n = `text` v = `Format`
                        )->tag( `Input`
                            )->a( n = `value` v = client->_bind( scan_type )
                        )->tag( `Label`
                            )->a( n = `text` v = `scanner`
                        )->tag( n = `BarcodeScannerButton` ns = `ndc`
                            )->a( n = `dialogTitle` v = `Barcode Scanner`
                            )->a( n = `scanSuccess` v = client->_event( val   = `ON_SCAN_SUCCESS`
                                                                        t_arg = VALUE #( ( `${$parameters>/text}` )
                                                                                         ( `${$parameters>/format}` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
