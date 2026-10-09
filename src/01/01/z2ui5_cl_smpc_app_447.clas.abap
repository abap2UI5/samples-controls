" @keywords messagebox message box sap.m messageboxinfo verticallayout button
" @summary MessageBox with the option to display detailed information.
" @origin sap.m.sample.MessageBoxInfo - https://sdk.openui5.org/entity/sap.m.MessageBox/sample/sap.m.sample.MessageBoxInfo (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_447 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    " the responsive padding classes every MessageBox of the sample carries
    CONSTANTS c_padding TYPE string VALUE `sapUiResponsivePadding--header sapUiResponsivePadding--content sapUiResponsivePadding--footer`.

    METHODS view_display.
    METHODS on_event.
    METHODS show_details_box
      IMPORTING
        type    TYPE string
        text    TYPE string
        title   TYPE string
        details TYPE string.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_447 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Button`
                )->a( n = `text`  v = `Show Details - Text`
                )->a( n = `press` v = client->_event( `TEXT_INFO` )
                )->a( n = `width` v = `250px`
                )->a( n = `class` v = `sapUiSmallMarginBottom`
            )->tag( `Button`
                )->a( n = `text`  v = `Show Details - FormattedText`
                )->a( n = `press` v = client->_event( `FORMATTED_TEXT_INFO` )
                )->a( n = `width` v = `250px`
                )->a( n = `class` v = `sapUiSmallMarginBottom`
            )->tag( `Button`
                )->a( n = `text`  v = `Show Details - JSON`
                )->a( n = `press` v = client->_event( `JSON_INFO` )
                )->a( n = `width` v = `250px`
                )->a( n = `class` v = `sapUiSmallMarginBottom`
            )->tag( `Button`
                )->a( n = `text`  v = `Show Details Async - Text`
                )->a( n = `press` v = client->_event( `TEXT_INFO_ASYNC` )
                )->a( n = `width` v = `250px`
                )->a( n = `class` v = `sapUiSmallMarginBottom` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `TEXT_INFO`.
        show_details_box(
            type    = `information`
            text    = `Information`
            title   = `Information`
            details = `Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, ` &&
                      `eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam ` &&
                      `voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione ` &&
                      `voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit,` &&
                      ` sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad ` &&
                      `minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi ` &&
                      `consequatur. Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel ` &&
                      `illum qui dolorem eum fugiat quo voluptas nulla pariatur.` ).

      WHEN `FORMATTED_TEXT_INFO`.
        " the details are markup - MessageBox renders them as a FormattedText
        show_details_box(
            type    = `error`
            text    = `Unable to load data.`
            title   = `Error`
            details = `<p><strong>This can happen if:</strong></p>` &&
                      `<ul>` &&
                      `<li>You are not connected to the internet</li>` &&
                      `<li>a backend component is not <em>available</em></li>` &&
                      `<li>or an underlying system is down</li>` &&
                      `</ul>` &&
                      `<p>Get more help <a href='//www.sap.com' target='_top'>here</a>.` ).

      WHEN `JSON_INFO`.
        " the original hands MessageBox a JS object; the same object as JSON
        show_details_box(
            type    = `error`
            text    = `Error message`
            title   = `Error`
            details = `{"glossary":{"title":"example glossary"}}` ).

      WHEN `TEXT_INFO_ASYNC`.
        " the original resolves the details from a Promise after 2 seconds;
        " the backend has the text right away and passes it as it is
        show_details_box(
            type    = `information`
            text    = `Information`
            title   = `Information`
            details = `Asynchronously fetched details` ).

    ENDCASE.

  ENDMETHOD.


  METHOD show_details_box.

    " Every option of this box - title, details, contentWidth, styleClass -
    " is a sap.m.MessageBox option, so the box is opened as the CONTROL it is:
    " the whitelisted global call takes the box type as its METHOD and the UI5
    " option object as its last argument. Two things follow from that, and
    " both make the port more faithful than the client-method call it replaces
    " ( contentWidth left message_box_display( ) in 2026-09 anyway ):
    "
    "   - `information` reaches MessageBox.information( ), which is what the
    "     original calls. No action set has to be pinned here anymore: the
    "     framework's remap onto show( ) - whose defaults WITH details are
    "     [OK, CANCEL] - is what grew the Cancel button this sample has not
    "     got, and there is no remap on this path.
    "   - the options travel as JSON, so the two characters JSON cares about
    "     are escaped below. The JSON details payload is a string that
    "     contains quotes, and a payload the backend cannot parse would be
    "     embedded as a plain string - the box would open with no options at
    "     all, quietly.
    DATA escaped LIKE details.
    DATA temp1 TYPE string_table.
    DATA temp2 LIKE LINE OF temp1.
    escaped = details.
    REPLACE ALL OCCURRENCES OF `\` IN escaped WITH `\\`.
    REPLACE ALL OCCURRENCES OF `"` IN escaped WITH `\"`.

    
    CLEAR temp1.
    INSERT `MESSAGE_BOX` INTO TABLE temp1.
    INSERT type INTO TABLE temp1.
    INSERT text INTO TABLE temp1.
    
    temp2 = |\{"title":"{ title }","details":"{ escaped }",| && |"contentWidth":"100px","styleClass":"{ c_padding }"\}|.
    INSERT temp2 INTO TABLE temp1.
    client->follow_up_action(
        val   = client->cs_event-control_global
        t_arg = temp1 ).

  ENDMETHOD.

ENDCLASS.
