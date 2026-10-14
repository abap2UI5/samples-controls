" @keywords overflowtoolbartokenizer overflow toolbar tokenizer sap.m token text input button verticallayout label overflowtoolbarlayoutdata
" @summary Tokenizer integration with sap.m.OverflowToolbar
" @origin sap.m.sample.OverflowToolbarTokenizer - https://sdk.openui5.org/entity/sap.m.OverflowToolbarTokenizer/sample/sap.m.sample.OverflowToolbarTokenizer (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_203 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_token,
        text TYPE string,
        key  TYPE string,
      END OF ty_s_token.
    DATA t_tokens  TYPE STANDARD TABLE OF ty_s_token WITH DEFAULT KEY.
    DATA new_token TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    TYPES:
      BEGIN OF ty_s_event_token,
        text TYPE string,
        key  TYPE string,
      END OF ty_s_event_token.
    TYPES ty_t_event_token TYPE STANDARD TABLE OF ty_s_event_token WITH DEFAULT KEY.

    METHODS view_display.

    METHODS on_event.
    METHODS event_tokens
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_event_token.
    METHODS json_objects
      IMPORTING
        json          TYPE string
      RETURNING
        VALUE(result) TYPE string_table.
    METHODS json_get_value
      IMPORTING
        json          TYPE string
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_203 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    DATA temp2 TYPE string_table.
    DATA temp3 TYPE string_table.
    DATA temp4 TYPE string_table.
    DATA temp5 TYPE string_table.
    DATA temp6 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `MESSAGE_TOAST` INTO TABLE temp1.
    INSERT `show` INTO TABLE temp1.
    INSERT `Token deleted: {0}` INTO TABLE temp1.
    INSERT `${$parameters>/tokens}[0].getText()` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `overflowToolbarTokenizer` INTO TABLE temp2.
    INSERT `removeToken` INTO TABLE temp2.
    INSERT `${$parameters>/tokens}[0].getId()` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `MESSAGE_TOAST` INTO TABLE temp3.
    INSERT `show` INTO TABLE temp3.
    INSERT `Token deleted: {0}` INTO TABLE temp3.
    INSERT `${$parameters>/tokens}[0].getText()` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `tokenizerMaxWidth` INTO TABLE temp4.
    INSERT `removeToken` INTO TABLE temp4.
    INSERT `${$parameters>/tokens}[0].getId()` INTO TABLE temp4.
    
    CLEAR temp5.
    INSERT `MESSAGE_TOAST` INTO TABLE temp5.
    INSERT `show` INTO TABLE temp5.
    INSERT `Token deleted: {0}` INTO TABLE temp5.
    INSERT `${$parameters>/tokens}[0].getText()` INTO TABLE temp5.
    
    CLEAR temp6.
    INSERT `tokenizerShowItems` INTO TABLE temp6.
    INSERT `removeToken` INTO TABLE temp6.
    INSERT `${$parameters>/tokens}[0].getId()` INTO TABLE temp6.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Toolbar`
            " sap.m.OverflowToolbarTokenizer is @ui5-experimental-since 1.139 (no plain @since tag,
            " invisible to scope-of/property gate) - out of 1.71 scope, see the sidecar deviation
            )->ele( `OverflowToolbarTokenizer`
                )->a( n = `id`          v = `toolbarTokenizer`
                )->a( n = `width`       v = `50%`
                )->a( n = `labelText`   v = `Tokenizer in sap.m.Toolbar:`
                " this is the tokenizer onAddToken/onTokenDelete work on, so its three
                " static tokens are folded into a bound aggregation (the app-085 pattern):
                " adding appends a row, deleting removes the row by its key
                )->a( n = `tokens`      v = client->_bind( t_tokens )
                " onTokenDelete iterates ALL deleted tokens - the event carries the
                " whole selection, not one token - so the ARRAY travels and ABAP
                " loops. The frontend marshals each control into its properties
                " (Lib.normalizeEventArgs), the same route app 103 uses
                )->a( n = `tokenDelete` v = client->_event( val = `TOKEN_DELETE` arg = `${$parameters>/tokens}` )
                )->ele( `tokens`
                    )->tag( `Token`
                        )->a( n = `text` v = `{TEXT}`
                        )->a( n = `key`  v = `{KEY}`

                )->end(
            )->end(
            )->tag( `Text`
                )->a( n = `text`  v = `Enter a token to add:`
                )->a( n = `width` v = `150px`
            )->tag( `Input`
                )->a( n = `id`    v = `NewTokenInput`
                )->a( n = `width` v = `200px`
                )->a( n = `value` v = client->_bind( new_token )
            )->tag( `Button`
                )->a( n = `text`  v = `Add Token`
                )->a( n = `press` v = client->_event( `ADD_TOKEN` )

        )->end(
        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->ele( `Label`
                )->a( n = `text` v = `OverflowToolbar with Tokenizer`
                )->ele( `layoutData`
                    )->tag( `OverflowToolbarLayoutData`
                        )->a( n = `priority` v = `Low`

                )->end(
            )->end(
            )->ele( `OverflowToolbar`
                )->a( n = `id`    v = `otbFilter`
                )->a( n = `width` v = `auto`
                )->ele( `content`
                    )->ele( `Button`
                        )->a( n = `icon` v = `sap-icon://notes`
                        )->a( n = `text` v = `Notes`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `OverflowToolbarTokenizer`
                        )->a( n = `id`          v = `overflowToolbarTokenizer`
                        )->a( n = `width`       v = `75%`
                        )->a( n = `labelText`   v = `Filter by:`
                        " onTokenDelete removes the token and toasts its text. The token is
                        " static here, so the wire removes it by ID - removeAggregation accepts
                        " an id (measured, scripts/probes/event-arg-expression-probe.mjs) - and
                        " the toast is composed on the client from the same event
                        )->a( n = `tokenDelete` v = client->follow_up_action(
                                  val   = client->cs_event-control_global
                                  t_arg = temp1 ) && `; ` &&
                                              client->follow_up_action(
                                  val   = client->cs_event-control_by_id
                                  t_arg = temp2 )
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `High`

                        )->end(
                        )->ele( `tokens`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 1`
                                )->a( n = `key`  v = `0001`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 2`
                                )->a( n = `key`  v = `0002`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 3`
                                )->a( n = `key`  v = `0003`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 4`
                                )->a( n = `key`  v = `0004`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 5`
                                )->a( n = `key`  v = `0005`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 6`
                                )->a( n = `key`  v = `0006`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 7`
                                )->a( n = `key`  v = `0007`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 8`
                                )->a( n = `key`  v = `0008`

                        )->end(
                    )->end(
                    )->tag( `ToolbarSpacer`

                )->end(
            )->end(
            )->tag( `Label`
                )->a( n = `text` v = `Tokenizer with max-width in OverflowToolbar`

            )->ele( `OverflowToolbar`
                )->a( n = `id`    v = `otbMaxWidth`
                )->a( n = `width` v = `100%`
                )->ele( `content`
                    )->ele( `Button`
                        )->a( n = `icon` v = `sap-icon://add`
                        )->a( n = `text` v = `Add custom criteria`
                        )->a( n = `type` v = `Transparent`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `OverflowToolbarTokenizer`
                        )->a( n = `id`          v = `tokenizerMaxWidth`
                        )->a( n = `width`       v = `45%`
                        )->a( n = `maxWidth`    v = `85%`
                        )->a( n = `labelText`   v = `Random label text:`
                        " onTokenDelete removes the token and toasts its text. The token is
                        " static here, so the wire removes it by ID - removeAggregation accepts
                        " an id (measured, scripts/probes/event-arg-expression-probe.mjs) - and
                        " the toast is composed on the client from the same event
                        )->a( n = `tokenDelete` v = client->follow_up_action(
                                  val   = client->cs_event-control_global
                                  t_arg = temp3 ) && `; ` &&
                                              client->follow_up_action(
                                  val   = client->cs_event-control_by_id
                                  t_arg = temp4 )
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `High`

                        )->end(
                        )->ele( `tokens`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 1`
                                )->a( n = `key`  v = `0001`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 2`
                                )->a( n = `key`  v = `0002`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 3`
                                )->a( n = `key`  v = `0003`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 4`
                                )->a( n = `key`  v = `0004`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 5`
                                )->a( n = `key`  v = `0005`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 1`
                                )->a( n = `key`  v = `0006`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 2`
                                )->a( n = `key`  v = `0007`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 3`
                                )->a( n = `key`  v = `0008`

                        )->end(
                    )->end(
                    )->ele( `Title`
                        )->a( n = `text`  v = `Title with Icon`
                        )->a( n = `level` v = `H1`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->tag( n = `Icon` ns = `core`
                        )->a( n = `src` v = `sap-icon://collaborate`
                    )->tag( `ToolbarSpacer`

                    )->ele( `Text`
                        )->a( n = `text` v = `Just a Simple Text`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `Button`
                        )->a( n = `text` v = `Accept`
                        )->a( n = `type` v = `Accept`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                )->end(
            )->end(
            )->tag( `Label`
                )->a( n = `text`  v = `Complex OverflowToolbar with input controls`
                )->a( n = `width` v = `100%`

            )->ele( `OverflowToolbar`
                )->a( n = `id`           v = `otbComplex`
                )->a( n = `width`        v = `100%`
                )->a( n = `ariaHasPopup` v = `dialog`
                )->a( n = `tooltip`      v = `This is a bar with tokenizer`
                )->ele( `content`
                    )->tag( n = `Icon` ns = `core`
                        )->a( n = `src` v = `sap-icon://collaborate`

                    )->ele( `Label`
                        )->a( n = `text` v = `Input controls`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `Button`
                        )->a( n = `text` v = `Regular Button`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `ToggleButton`
                        )->a( n = `text` v = `Toggle me`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `Input`
                        )->a( n = `placeholder` v = `Input`
                        )->a( n = `width`       v = `200px`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `DateTimePicker`
                        )->a( n = `placeholder` v = `DateTimePicker`
                        )->a( n = `width`       v = `200px`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `DateRangeSelection`
                        )->a( n = `placeholder` v = `DateRangeSelection`
                        )->a( n = `width`       v = `200px`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `RadioButton`
                        )->a( n = `text`      v = `Option a`
                        )->a( n = `groupName` v = `a`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `RadioButton`
                        )->a( n = `text`      v = `Option b`
                        )->a( n = `groupName` v = `a`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `OverflowToolbarTokenizer`
                        )->a( n = `id`          v = `tokenizerShowItems`
                        )->a( n = `width`       v = `35%`
                        )->a( n = `labelText`   v = `Show items:`
                        )->a( n = `tokenDelete` v = client->follow_up_action(
                                  val   = client->cs_event-control_global
                                  t_arg = temp5 ) && `; ` &&
                                              client->follow_up_action(
                                  val   = client->cs_event-control_by_id
                                  t_arg = temp6 )
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `High`

                        )->end(
                        )->ele( `tokens`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 1`
                                )->a( n = `key`  v = `0001`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 2`
                                )->a( n = `key`  v = `0002`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 3`
                                )->a( n = `key`  v = `0003`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 4 - long text example`
                                )->a( n = `key`  v = `0004`
                            )->tag( `Token`
                                )->a( n = `text` v = `Token 5`
                                )->a( n = `key`  v = `0005`

                        )->end(
                    )->end(
                    )->ele( `SegmentedButton`
                        )->ele( `items`
                            )->tag( `SegmentedButtonItem`
                                )->a( n = `text` v = `Left Button`
                            )->tag( `SegmentedButtonItem`
                                )->a( n = `icon`    v = `sap-icon://notes`
                                )->a( n = `tooltip` v = `Notes`
                            )->tag( `SegmentedButtonItem`
                                )->a( n = `text`    v = `Disabled Button`
                                )->a( n = `enabled` v = `false`
                            )->tag( `SegmentedButtonItem`
                                )->a( n = `text` v = `Right Button`

                        )->end(
                    )->end(
                    )->tag( `ToolbarSpacer`
                    )->tag( `Title`
                        )->a( n = `text`  v = `Example Title`
                        )->a( n = `level` v = `H1` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE z2ui5_cl_smpc_app_203=>ty_s_token.
        DATA temp4 TYPE string.
        DATA temp5 TYPE z2ui5_cl_smpc_app_203=>ty_t_event_token.
        DATA temp6 LIKE LINE OF temp5.
        DATA del LIKE REF TO temp6.

    CASE client->get_event( ).

      WHEN `ADD_TOKEN`.
        " onAddToken: an empty input only toasts, otherwise the token is appended
        " with text = key = the entered value and the input is cleared
        IF new_token IS INITIAL.
          client->message_toast_display( `Please enter a token text.` ).
          RETURN.
        ENDIF.
        
        CLEAR temp3.
        temp3-text = new_token.
        temp3-key = new_token.
        INSERT temp3 INTO TABLE t_tokens.
        client->message_toast_display( |Token added: { new_token }| ).
        
        CLEAR temp4.
        new_token = temp4.
      WHEN `TOKEN_DELETE`.
        " onTokenDelete: aDeletedTokens.forEach - toast each token's text and
        " remove it. Selecting several tokens and pressing Delete really does
        " deliver several: Tokenizer fires with getSelectedTokens( ) when there
        " is a selection, and with the focused token otherwise
        
        temp5 = event_tokens( client->get_event_arg( ) ).
        
        
        LOOP AT temp5 REFERENCE INTO del.
          client->message_toast_display( |Token deleted: { del->text }| ).
          DELETE t_tokens WHERE key = del->key.
        ENDLOOP.

    ENDCASE.

  ENDMETHOD.


  METHOD event_tokens.

    DATA json TYPE string.
    DATA temp6 TYPE string_table.
    DATA object LIKE LINE OF temp6.
      DATA temp7 TYPE z2ui5_cl_smpc_app_203=>ty_s_event_token.
    json = condense( val ).
    IF json IS INITIAL.
      RETURN.
    ENDIF.

    " The frontend marshals each control into an object of its ID plus ALL
    " its public properties, so this reads the fields the port models and
    " ignores the rest - which is what the corresponding-only mapping used
    " to do. Written by hand: there is no released JSON parser, and the
    " vendored ajson copy is framework-internal.
    
    temp6 = json_objects( json ).
    
    LOOP AT temp6 INTO object.
      
      CLEAR temp7.
      temp7-text = json_get_value( json = object name = `text` ).
      temp7-key = json_get_value( json = object name = `key` ).
      INSERT temp7 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.


  METHOD json_objects.

    " Cut the array into its objects. abap2UI5 releases no JSON parser and
    " the vendored ajson copy is framework-internal (the linter's
    " non-released-api rule reports it, correctly), so the split is one
    " character walk - and it is a walk rather than a SPLIT on `},{` because
    " a brace inside a STRING is text, not structure.
    DATA depth TYPE i.
    DATA in_string LIKE abap_false.
    DATA escaped LIKE abap_false.
    DATA start TYPE i.
    DATA pos TYPE i.
    DATA length TYPE i.
      DATA char TYPE string.
        DATA temp1 TYPE xsdboolean.
    depth     = 0.
    
    in_string = abap_false.
    
    escaped = abap_false.
    
    start     = 0.
    
    pos       = 0.
    
    length    = strlen( json ).

    WHILE pos < length.
      
      char = substring( val = json off = pos len = 1 ).

      IF escaped = abap_true.
        escaped = abap_false.
      ELSEIF in_string = abap_true AND char = `\`.
        escaped = abap_true.
      ELSEIF char = `"`.
        
        temp1 = boolc( in_string = abap_false ).
        in_string = temp1.
      ELSEIF in_string = abap_false AND char = `{`.
        IF depth = 0.
          start = pos.
        ENDIF.
        depth = depth + 1.
      ELSEIF in_string = abap_false AND char = `}`.
        depth = depth - 1.
        IF depth = 0.
          INSERT substring( val = json off = start len = pos - start + 1 ) INTO TABLE result.
        ENDIF.
      ENDIF.

      pos = pos + 1.
    ENDWHILE.

  ENDMETHOD.


  METHOD json_get_value.

    " One string field of ONE object: find `"<name>":"` and take what stands
    " up to the next quote. The search is case-insensitive because the key is
    " the UI5 property name (camelCase) and this reads it in lower case.
    " Same reader as Z2UI5_CL_SMP_APP_327 in abap2UI5/samples, and the same
    " limit: it reads what the FRAMEWORK wrote and does not resolve escapes,
    " which a payload composed from free user input would need.
    DATA marker TYPE string.
    DATA offset TYPE i.
    marker = |"{ name }":"|.

    
    offset = find( val = json sub = marker case = abap_false ).
    IF offset < 0.
      RETURN.
    ENDIF.

    result = substring_before( val = substring( val = json
                                                off = offset + strlen( marker ) )
                               sub = `"` ).

  ENDMETHOD.


  METHOD model_init.

    " the three tokens the sample declares on the first tokenizer
    DATA temp8 LIKE t_tokens.
    DATA temp9 LIKE LINE OF temp8.
    CLEAR temp8.
    
    temp9-text = `Token 1`.
    temp9-key = `0001`.
    INSERT temp9 INTO TABLE temp8.
    temp9-text = `Token 2`.
    temp9-key = `0002`.
    INSERT temp9 INTO TABLE temp8.
    temp9-text = `Token 3`.
    temp9-key = `0003`.
    INSERT temp9 INTO TABLE temp8.
    t_tokens = temp8.

  ENDMETHOD.


ENDCLASS.
