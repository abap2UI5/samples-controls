" @keywords uploadsetwithtable upload setwith table sap.m.plugins uploadsetwithtableplugin.gridtablesimple dynamicpage overflowtoolbar title toolbarspacer actionsplaceholder button
" @summary This example demonstrates the usage of UploadSetwithTable plugin for grid table with the features of upload, download, drag & drop, remove and rename of files. It also demonstrates how the uploaded files can be displayed in a table.
" @origin sap.m.sample.UploadSetwithTablePlugin.GridTableSimple - https://sdk.openui5.org/entity/sap.m.plugins.UploadSetwithTable/sample/sap.m.sample.UploadSetwithTablePlugin.GridTableSimple (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_654 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_item,
        id             TYPE string,
        filename       TYPE string,
        mediatype      TYPE string,
        imageurl       TYPE string,
        url            TYPE string,
        revision       TYPE string,
        status         TYPE string,
        filesize       TYPE i,
        lastmodifiedby TYPE string,
        lastmodified   TYPE string,
        documenttype   TYPE string,
        previewable    TYPE abap_bool,
        trustedsource  TYPE abap_bool,
        uploadstate    TYPE string,
        icon           TYPE string,
        filesize_units TYPE string,
      END OF ty_s_item.
    TYPES temp1_5736bc7f39 TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
DATA t_items TYPE temp1_5736bc7f39.
    " onSelectionChange: Download for one or more rows, the rest for exactly one
    DATA download_enabled TYPE abap_bool.
    DATA single_enabled   TYPE abap_bool.
    " the AddViaUrl fragment, in its Add URL and Edit URL shapes
    DATA dialog_title     TYPE string.
    DATA apply_text       TYPE string.
    DATA url_required     TYPE abap_bool.
    DATA url_input        TYPE string.
    DATA url_state        TYPE string.
    DATA url_state_text   TYPE string.
    DATA name_input       TYPE string.
    DATA name_state       TYPE string.
    DATA name_state_text  TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    " the selected rows (as /<index>) and the binding path of the row a removal
    " asks about; sap.ui.table keeps its selection by index, so after a removal
    " both stay on the same indices, as in the original
    DATA t_selected  TYPE string_table.
    DATA remove_path TYPE string.
    DATA is_edit     TYPE abap_bool.
    DATA upload_no   TYPE i.

    METHODS view_display.
    METHODS popup_url_display.
    METHODS on_event.
    METHODS url_apply.
    METHODS remove_ask
      IMPORTING
        path TYPE string.
    METHODS name_valid
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS url_valid
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS row_add
      IMPORTING
        filename  TYPE string
        mediatype TYPE string
        url       TYPE string
        filesize  TYPE i.
    METHODS selected_index
      RETURNING
        VALUE(result) TYPE i.
    METHODS row_index
      IMPORTING
        path          TYPE string
      RETURNING
        VALUE(result) TYPE i.
    METHODS row_derive
      CHANGING
        row TYPE ty_s_item.
    METHODS icon_for
      IMPORTING
        mediatype     TYPE string
        filename      TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS size_with_units
      IMPORTING
        size          TYPE i
      RETURNING
        VALUE(result) TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_654 IMPLEMENTATION.

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
    DATA temp3 LIKE LINE OF temp2.
    DATA temp4 TYPE string_table.
    DATA temp5 LIKE LINE OF temp4.
    DATA temp6 TYPE string_table.
    DATA temp7 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp8 TYPE string_table.
    DATA temp9 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `IMAGEURL` INTO TABLE temp1.
    INSERT `UPLOADSTATE` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `uploadSetPlugin` INTO TABLE temp2.
    INSERT `download` INTO TABLE temp2.
    
    temp3 = `$controller.getView().byId('table-uploadSet').getContextByIndex(` && `$controller.getView().byId('table-uploadSet').getSelectedIndices()[0])`.
    INSERT temp3 INTO TABLE temp2.
    INSERT `true` INTO TABLE temp2.
    
    CLEAR temp4.
    INSERT `uploadSetPlugin` INTO TABLE temp4.
    INSERT `renameItem` INTO TABLE temp4.
    
    temp5 = `$controller.getView().byId('table-uploadSet').getContextByIndex(` && `$controller.getView().byId('table-uploadSet').getSelectedIndices()[0])`.
    INSERT temp5 INTO TABLE temp4.
    
    CLEAR temp6.
    INSERT `${$parameters>/item}.getFileName()` INTO TABLE temp6.
    INSERT `${$parameters>/item}.getMediaType()` INTO TABLE temp6.
    INSERT `${$parameters>/item}.getFileObject().size` INTO TABLE temp6.
    
    CLEAR temp7.
    temp7-check_prevent_default = abap_true.
    temp7-check_queue_last = abap_true.
    
    CLEAR temp8.
    INSERT `${$parameters>/item}.getBindingContext().getPath()` INTO TABLE temp8.
    INSERT `${$parameters>/item}.getFileName()` INTO TABLE temp8.
    
    CLEAR temp9.
    INSERT `uploadSetPlugin` INTO TABLE temp9.
    INSERT `openFilePreview` INTO TABLE temp9.
    INSERT `$event.oSource.getBindingContext()` INTO TABLE temp9.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`         v = `sap.ui.table`
        )->a( n = `xmlns:m`       v = `sap.m`
        )->a( n = `xmlns:mvc`     v = `sap.ui.core.mvc`
        )->a( n = `xmlns:f`       v = `sap.f`
        )->a( n = `xmlns:core`    v = `sap.ui.core`
        )->a( n = `xmlns:upload`  v = `sap.m.upload`
        )->a( n = `xmlns:plugins` v = `sap.m.plugins`
        )->a( n = `height`        v = `100%`
        )->a( n = `displayBlock`  v = `true`

        )->ele( n = `DynamicPage` ns = `f`
            )->a( n = `id` v = `page`

            )->ele( n = `content` ns = `f`
                )->ele( `Table`
                    )->a( n = `id`                 v = `table-uploadSet`
                    " IMAGEURL and UPLOADSTATE stay absent where the mock has
                    " none, so the view's undefined checks read as in the sample
                    )->a( n = `rows`               v = client->_bind( val                = t_items
                                                                      omit_initial_paths = temp1 )
                    )->a( n = `selectionMode`      v = `MultiToggle`
                    )->a( n = `rowSelectionChange` v = client->_event( val = `SELECTION`
                                                                       arg = `$event.oSource.getSelectedIndices().join()` )

                    )->ele( `extension`
                        )->ele( n = `OverflowToolbar` ns = `m`
                            )->a( n = `style` v = `Clear`

                            )->tag( n = `Title` ns = `m`
                                )->a( n = `text`  v = |Documents (\{= ${ client->_bind( t_items ) }.length\})|
                                )->a( n = `level` v = `H2`
                            )->tag( n = `ToolbarSpacer` ns = `m`
                            )->tag( n = `ActionsPlaceholder` ns = `upload`
                                )->a( n = `id`             v = `uploadButton`
                                )->a( n = `placeholderFor` v = `UploadButtonPlaceholder`
                            )->tag( n = `Button` ns = `m`
                                )->a( n = `id`      v = `downloadSelectedButton`
                                )->a( n = `text`    v = `Download`
                                )->a( n = `enabled` v = client->_bind( download_enabled )
                                )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                  t_arg = temp2 )

                            )->ele( n = `MenuButton` ns = `m`
                                )->a( n = `text` v = `Add`

                                )->ele( n = `menu` ns = `m`
                                    )->ele( n = `Menu` ns = `m`
                                        )->tag( n = `MenuItem` ns = `m`
                                            )->a( n = `text`  v = `URL`
                                            )->a( n = `press` v = client->_event( `ADD_URL` )

                                    )->end(
                                )->end(
                                )->ele( n = `layoutData` ns = `m`
                                    )->tag( n = `OverflowToolbarLayoutData` ns = `m`
                                        )->a( n = `priority` v = `AlwaysOverflow`

                                )->end(
                            )->end(
                            )->ele( n = `Button` ns = `m`
                                )->a( n = `id`      v = `removeDocumentButton`
                                )->a( n = `text`    v = `Remove`
                                )->a( n = `press`   v = client->_event( `REMOVE_SELECTED` )
                                )->a( n = `enabled` v = client->_bind( single_enabled )

                                )->ele( n = `layoutData` ns = `m`
                                    )->tag( n = `OverflowToolbarLayoutData` ns = `m`
                                        )->a( n = `priority` v = `AlwaysOverflow`

                                )->end(
                            )->end(
                            )->ele( n = `Button` ns = `m`
                                )->a( n = `id`      v = `renameButton`
                                )->a( n = `enabled` v = client->_bind( single_enabled )
                                )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                  t_arg = temp4 )
                                )->a( n = `text`    v = `Rename`

                                )->ele( n = `layoutData` ns = `m`
                                    )->tag( n = `OverflowToolbarLayoutData` ns = `m`
                                        )->a( n = `priority` v = `AlwaysOverflow`

                                )->end(
                            )->end(
                            )->ele( n = `Button` ns = `m`
                                )->a( n = `id`      v = `editUrlButton`
                                )->a( n = `text`    v = `Edit URL`
                                )->a( n = `enabled` v = client->_bind( single_enabled )
                                )->a( n = `press`   v = client->_event( `EDIT_URL` )

                                )->ele( n = `layoutData` ns = `m`
                                    )->tag( n = `OverflowToolbarLayoutData` ns = `m`
                                        )->a( n = `priority` v = `AlwaysOverflow`

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                    )->ele( `dependents`
                        )->ele( n = `UploadSetwithTable` ns = `plugins`
                            " the id is added - the port calls the plugin by id where the
                            " controller kept the instance onActivated handed it
                            )->a( n = `id`                     v = `uploadSetPlugin`
                            )->a( n = `uploadUrl`              v = `/uploadFiles`
                            )->a( n = `multiple`               v = `true`
                            " the mock server's part: the upload is vetoed and the backend
                            " adds the row the fake 201 response would have created
                            )->a( n = `beforeUploadStarts`     v = client->_event( val    = `UPLOAD`
                                                                                   t_arg  = temp6
                                                                                   s_ctrl = temp7 )
                            )->a( n = `itemRenamed`            v = client->_event( val   = `RENAMED`
                                                                                   t_arg = temp8 )
                            )->a( n = `cloudFilePickerEnabled` v = `true`
                            )->a( n = `actions`                v = `uploadButton`

                            " the paths name the model's upper-case ABAP fields
                            )->tag( n = `UploadItemConfiguration` ns = `upload`
                                )->a( n = `fileNamePath`        v = `FILENAME`
                                )->a( n = `mediaTypePath`       v = `MEDIATYPE`
                                )->a( n = `urlPath`             v = `URL`
                                )->a( n = `previewablePath`     v = `PREVIEWABLE`
                                )->a( n = `fileSizePath`        v = `FILESIZE`
                                )->a( n = `isTrustedSourcePath` v = `TRUSTEDSOURCE`

                        )->end(
                    )->end(
                    )->ele( `rowSettingsTemplate`
                        )->tag( `RowSettings`
                            )->a( n = `highlight` v = `{= ${UPLOADSTATE} === 'Complete' ? 'Indication05' : null }`

                    )->end(
                    )->ele( `columns`
                        )->ele( `Column`
                            )->a( n = `width` v = `20%`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `File Name`

                            )->ele( `template`
                                )->ele( n = `HBox` ns = `m`
                                    )->a( n = `class` v = `sapUiTinyMargin`

                                    )->tag( n = `Image` ns = `m`
                                        )->a( n = `src`     v = `{IMAGEURL}`
                                        )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`
                                        )->a( n = `visible` v = `{= ${IMAGEURL} !== undefined}`
                                    " getIconSrc runs in ABAP: the row carries the finished icon
                                    )->tag( n = `Icon` ns = `core`
                                        )->a( n = `src`     v = `{ICON}`
                                        )->a( n = `visible` v = `{= ${IMAGEURL} === undefined || ${IMAGEURL} === '' }`
                                        )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`

                                    )->ele( n = `VBox` ns = `m`
                                        )->a( n = `class` v = `sapUiTinyMargin sapUiSmallMarginBegin`

                                        )->tag( n = `Link` ns = `m`
                                            )->a( n = `text`  v = `{FILENAME}`
                                            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                            t_arg = temp9 )
                                            )->a( n = `class` v = `sapUiTinyMarginBottom`
                                        )->tag( n = `Text` ns = `m`
                                            )->a( n = `text` v = `{DOCUMENTTYPE}`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `ID`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text` v = `{ID}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Revision`

                            )->ele( `template`
                                )->tag( n = `Link` ns = `m`
                                    )->a( n = `text` v = `{REVISION}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Status`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text` v = `{STATUS}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `File Size`

                            " getFileSizeWithUnits runs in ABAP as well
                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text` v = `{FILESIZE_UNITS}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Last Modified`

                            )->ele( `template`
                                )->ele( n = `VBox` ns = `m`
                                    )->tag( n = `Text` ns = `m`
                                        )->a( n = `text` v = `{LASTMODIFIEDBY}`
                                    )->tag( n = `Text` ns = `m`
                                        )->a( n = `class` v = `sapUiTinyMarginTop`
                                        )->a( n = `text`  v = `{LASTMODIFIED}`

                                )->end(
                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->ele( `template`
                                )->tag( n = `Button` ns = `m`
                                    )->a( n = `class` v = `sapUiTinyMarginBegin`
                                    )->a( n = `type`  v = `Transparent`
                                    )->a( n = `icon`  v = `sap-icon://decline`
                                    )->a( n = `press` v = client->_event( val = `REMOVE_ROW`
                                                                          arg = `$event.oSource.getBindingContext().getPath()` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD popup_url_display.

    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`             v = `sap.m`
        )->a( n = `xmlns:core`        v = `sap.ui.core`
        )->a( n = `xmlns:form`        v = `sap.ui.layout.form`
        )->a( n = `templateShareable` v = `false`
        )->a( n = `class`             v = `sapUiTinyMarginTop`

        )->ele( `Dialog`
            )->a( n = `id`            v = `addViaUrlDialog`
            )->a( n = `title`         v = client->_bind( dialog_title )
            )->a( n = `contentWidth`  v = `28rem`
            )->a( n = `contentHeight` v = `15rem`
            )->a( n = `class`         v = `sapUiSmallMargin`

            )->ele( `content`
                )->ele( n = `SimpleForm` ns = `form`
                    )->a( n = `editable` v = `true`
                    )->a( n = `id`       v = `addViaUrlSimpleform`

                    )->tag( `Label`
                        )->a( n = `id`       v = `urlInputLabel`
                        )->a( n = `text`     v = `URL`
                        )->a( n = `required` v = client->_bind( url_required )
                    )->tag( `Input`
                        )->a( n = `id`             v = `urlInput`
                        )->a( n = `value`          v = client->_bind( url_input )
                        )->a( n = `valueState`     v = client->_bind( url_state )
                        )->a( n = `valueStateText` v = client->_bind( url_state_text )
                    )->tag( `Label`
                        )->a( n = `id`       v = `nameInputLabel`
                        )->a( n = `text`     v = `Name`
                        )->a( n = `required` v = `true`
                    )->tag( `Input`
                        )->a( n = `id`             v = `nameInput`
                        )->a( n = `value`          v = client->_bind( name_input )
                        )->a( n = `valueState`     v = client->_bind( name_state )
                        )->a( n = `valueStateText` v = client->_bind( name_state_text )

                )->end(
            )->end(
            )->ele( `beginButton`
                )->tag( `Button`
                    )->a( n = `id`    v = `addDocumentBtn`
                    )->a( n = `text`  v = client->_bind( apply_text )
                    )->a( n = `type`  v = `Emphasized`
                    )->a( n = `press` v = client->_event( `URL_APPLY` )

            )->end(
            )->ele( `endButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `Cancel`
                    )->a( n = `press` v = client->follow_up_action( client->cs_event-popup_close ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE string_table.
          TYPES temp2 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA indices TYPE temp2.
          DATA selected LIKE LINE OF indices.
            DATA temp4 LIKE LINE OF t_selected.
        DATA temp1 TYPE xsdboolean.
        DATA temp7 TYPE xsdboolean.
        DATA current TYPE i.
        DATA row LIKE LINE OF t_items.
        FIELD-SYMBOLS <temp4> LIKE LINE OF t_items.
        DATA temp5 LIKE sy-tabix.
          DATA target TYPE i.
            FIELD-SYMBOLS <temp5> LIKE LINE OF t_items.
            DATA temp6 LIKE sy-tabix.
            FIELD-SYMBOLS <temp7> LIKE LINE OF t_items.
            DATA temp8 LIKE sy-tabix.
          FIELD-SYMBOLS <temp9> LIKE LINE OF t_selected.
          DATA temp10 LIKE sy-tabix.
          DATA index TYPE i.
        DATA temp11 TYPE i.
        DATA renamed TYPE i.
          FIELD-SYMBOLS <temp12> LIKE LINE OF t_items.
          DATA temp13 LIKE sy-tabix.

    CASE client->get_event( ).

      WHEN `SELECTION`.
        " onSelectionChange - getSelectedIndices( ); the table neither sorts nor
        " filters, so a row index is the model index, kept as a /<index> path
        
        CLEAR temp3.
        t_selected = temp3.
        IF client->get_event_arg( ) IS NOT INITIAL.
          

          SPLIT client->get_event_arg( ) AT `,` INTO TABLE indices.
          
          LOOP AT indices INTO selected.
            
            temp4 = |/{ selected }|.
            INSERT temp4 INTO TABLE t_selected.
          ENDLOOP.
        ENDIF.
        
        temp1 = boolc( t_selected IS NOT INITIAL ).
        download_enabled = temp1.
        
        temp7 = boolc( lines( t_selected ) = 1 ).
        single_enabled   = temp7.

      WHEN `ADD_URL`.
        " openAddOrEditDialog in its Add shape
        is_edit         = abap_false.
        dialog_title    = `Add URL`.
        apply_text      = `Add`.
        url_required    = abap_true.
        url_input       = ``.
        name_input      = ``.
        url_state       = `None`.
        url_state_text  = ``.
        name_state      = `None`.
        name_state_text = ``.
        popup_url_display( ).

      WHEN `EDIT_URL`.
        " onEditUrl - the same fragment as Edit URL, filled from the selected row
        
        current = selected_index( ).
        IF current = 0.
          RETURN.
        ENDIF.
        
        
        
        temp5 = sy-tabix.
        READ TABLE t_items INDEX current ASSIGNING <temp4>.
        sy-tabix = temp5.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        row = <temp4>.
        is_edit         = abap_true.
        dialog_title    = `Edit URL`.
        apply_text      = `Apply`.
        url_required    = abap_false.
        url_input       = row-url.
        name_input      = row-filename.
        url_state       = `None`.
        url_state_text  = ``.
        name_state      = `None`.
        name_state_text = ``.
        popup_url_display( ).

      WHEN `URL_APPLY`.
        url_apply( ).

      WHEN `EDIT_CONFIRM`.
        IF client->get_event_arg( ) = `Save`.
          " the Save button validates (value states) and applies regardless
          name_valid( ).
          url_valid( ).
          
          target = selected_index( ).
          IF target > 0.
            
            
            temp6 = sy-tabix.
            READ TABLE t_items INDEX target ASSIGNING <temp5>.
            sy-tabix = temp6.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            <temp5>-filename = name_input.
            
            
            temp8 = sy-tabix.
            READ TABLE t_items INDEX target ASSIGNING <temp7>.
            sy-tabix = temp8.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            <temp7>-url      = url_input.
          ENDIF.
          client->popup_destroy( ).
        ENDIF.

      WHEN `REMOVE_SELECTED`.
        IF t_selected IS NOT INITIAL.
          
          
          temp10 = sy-tabix.
          READ TABLE t_selected INDEX 1 ASSIGNING <temp9>.
          sy-tabix = temp10.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          remove_ask( <temp9> ).
        ENDIF.

      WHEN `REMOVE_ROW`.
        remove_ask( client->get_event_arg( ) ).

      WHEN `REMOVE_CLOSE`.
        IF client->get_event_arg( ) = `Remove`.
          
          index = row_index( remove_path ).
          IF index BETWEEN 1 AND lines( t_items ).
            DELETE t_items INDEX index.
          ENDIF.
        ENDIF.

      WHEN `UPLOAD`.
        " the file the FileUploader picked, as the mock server would answer it
        
        temp11 = client->get_event_arg( 3 ).
        row_add( filename  = client->get_event_arg( )
                 mediatype = client->get_event_arg( 2 )
                 url       = ``
                 filesize  = temp11 ).
        client->message_toast_display( `Document Added` ).

      WHEN `RENAMED`.
        " onDocumentRenamedSuccess writes the new name into the row
        
        renamed = row_index( client->get_event_arg( ) ).
        IF renamed BETWEEN 1 AND lines( t_items ).
          
          
          temp13 = sy-tabix.
          READ TABLE t_items INDEX renamed ASSIGNING <temp12>.
          sy-tabix = temp13.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp12>-filename = client->get_event_arg( 2 ).
        ENDIF.
        client->message_toast_display( text = `Document Renamed.` duration = `2000` ).

    ENDCASE.

  ENDMETHOD.


  METHOD url_apply.
        DATA temp14 TYPE string_table.
    DATA has_error TYPE abap_bool.
    DATA temp8 TYPE xsdboolean.

    " handleAddViaUrl
    IF is_edit = abap_true.
      IF name_valid( ) = abap_true.
        " showEditConfirmation - a Message dialog in the Warning state
        
        CLEAR temp14.
        INSERT `Save` INTO TABLE temp14.
        INSERT `DiscardChanges` INTO TABLE temp14.
        client->message_box_display( text             = `You have made changes to this object. What would you like to do?`
                                     type             = `warning`
                                     title            = `Warning`
                                     actions          = temp14
                                     emphasizedaction = `Save`
                                     onclose          = `EDIT_CONFIRM` ).
      ELSE.
        client->message_toast_display( `No Changes found` ).
      ENDIF.
      RETURN.
    ENDIF.
    
    
    temp8 = boolc( name_valid( ) = abap_false ).
    has_error = temp8.
    IF url_valid( ) = abap_false.
      has_error = abap_true.
    ENDIF.
    IF has_error = abap_false.
      " uploadItemViaUrl - the mock server answers with the typed URL as the
      " document URL and an empty file
      row_add( filename  = name_input
               mediatype = ``
               url       = url_input
               filesize  = 0 ).
      client->popup_destroy( ).
      client->message_toast_display( `Document Added` ).
    ENDIF.

  ENDMETHOD.


  METHOD remove_ask.

    " removeItem - MessageBox.warning; the icon is the warning box's own
    DATA index TYPE i.
    DATA temp16 TYPE string_table.
    FIELD-SYMBOLS <temp6> LIKE LINE OF t_items.
    DATA temp7 LIKE sy-tabix.
    index = row_index( path ).
    IF index NOT BETWEEN 1 AND lines( t_items ).
      RETURN.
    ENDIF.
    remove_path = path.
    
    CLEAR temp16.
    INSERT `Remove` INTO TABLE temp16.
    INSERT `CANCEL` INTO TABLE temp16.
    
    
    temp7 = sy-tabix.
    READ TABLE t_items INDEX index ASSIGNING <temp6>.
    sy-tabix = temp7.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    client->message_box_display( text             = |Are you sure you want to remove the document { <temp6>-filename } ?|
                                 type             = `warning`
                                 actions          = temp16
                                 emphasizedaction = `Remove`
                                 styleclass       = `sapMUSTRemovePopoverContainer`
                                 initialfocus     = `CANCEL`
                                 onclose          = `REMOVE_CLOSE` ).

  ENDMETHOD.


  METHOD name_valid.

    " _isValidName
    IF name_input IS INITIAL.
      name_state      = `Error`.
      name_state_text = `Text is either empty or contains special characters`.
    ELSE.
      name_state = `None`.
      result     = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD url_valid.

    " _validateAddOrEditUrlDialog's URL half - the sample's regex is unanchored,
    " so a scheme followed by one non-blank character is what it requires
    FIND REGEX `(ftp|http|https)://\S` IN url_input.
    IF sy-subrc <> 0.
      url_state      = `Error`.
      url_state_text = `Enter Valid URL`.
    ELSE.
      url_state = `None`.
      result    = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD row_add.
    DATA temp18 TYPE ty_s_item.
    DATA row LIKE temp18.

    " the mock server's Create branch - unshift the new document
    upload_no = upload_no + 1.
    
    CLEAR temp18.
    temp18-id = |{ upload_no }|.
    temp18-filename = filename.
    temp18-mediatype = mediatype.
    temp18-url = url.
    temp18-uploadstate = `Complete`.
    temp18-revision = `00`.
    temp18-status = `In work`.
    temp18-filesize = filesize.
    temp18-lastmodifiedby = `Jane Burns`.
    temp18-lastmodified = `10/03/21, 10:03:00 PM`.
    temp18-documenttype = `Invoice`.
    temp18-trustedsource = abap_true.
    
    row = temp18.
    row_derive( CHANGING row = row ).
    INSERT row INTO t_items INDEX 1.

  ENDMETHOD.


  METHOD selected_index.
    FIELD-SYMBOLS <temp19> LIKE LINE OF t_selected.
    DATA temp20 LIKE sy-tabix.

    " the one selected row the toolbar actions work on - 0 when there is none
    IF t_selected IS INITIAL.
      RETURN.
    ENDIF.
    
    
    temp20 = sy-tabix.
    READ TABLE t_selected INDEX 1 ASSIGNING <temp19>.
    sy-tabix = temp20.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    result = row_index( <temp19> ).
    IF result > lines( t_items ).
      result = 0.
    ENDIF.

  ENDMETHOD.


  METHOD row_index.

    " a row's binding path ends in its 0-based index: /T_ITEMS/3 is the 4th row
    DATA slash TYPE i.
    DATA digits TYPE string.
    DATA temp21 TYPE i.
    slash = find( val = path sub = `/` occ = -1 ).
    IF slash < 0.
      RETURN.
    ENDIF.
    
    digits = substring( val = path off = slash + 1 ).
    IF digits IS INITIAL OR digits CN `0123456789`.
      RETURN.
    ENDIF.
    
    temp21 = digits.
    result = temp21 + 1.

  ENDMETHOD.


  METHOD row_derive.

    row-icon           = icon_for( mediatype = row-mediatype filename = row-filename ).
    row-filesize_units = size_with_units( row-filesize ).

  ENDMETHOD.


  METHOD icon_for.
      DATA type TYPE string.
    DATA dot TYPE i.
    DATA extension TYPE string.

    " UploadSetwithTable.getIconForFileType: IconPool's media type table, or the
    " file extension when there is no media type
    IF mediatype IS NOT INITIAL.
      
      type = to_lower( mediatype ).
      CASE type.
        WHEN `application/msword` OR `application/vnd.google-apps.document` OR `application/rtf`
            OR `application/vnd.openxmlformats-officedocument.wordprocessingml.document`.
          result = `sap-icon://doc-attachment`.
        WHEN `application/pdf`.
          result = `sap-icon://pdf-attachment`.
        WHEN `application/msexcel` OR `application/vnd.ms-excel` OR `application/vnd.google-apps.spreadsheet`
            OR `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
            OR `application/vnd.ms-excel.sheet.macroenabled.12`
            OR `application/vnd.openxmlformats-officedocument.spreadsheetml.template`
            OR `application/vnd.ms-excel.template.macroenabled.12`
            OR `application/vnd.ms-excel.sheet.binary.macroenabled.12`
            OR `application/vnd.ms-excel.addin.macroenabled.12`.
          result = `sap-icon://excel-attachment`.
        WHEN `application/vnd.ms-powerpoint` OR `application/vnd.google-apps.presentation` OR `application/mspowerpoint`
            OR `application/vnd.openxmlformats-officedocument.presentationml.presentation`
            OR `application/vnd.openxmlformats-officedocument.presentationml.slideshow`.
          result = `sap-icon://ppt-attachment`.
        WHEN `application/xml` OR `application/xhtml+xml` OR `application/x-httpd-php` OR `application/x-javascript`
            OR `text/html`.
          result = `sap-icon://attachment-html`.
        WHEN `application/gzip` OR `application/x-rar-compressed` OR `application/x-tar` OR `application/zip`.
          result = `sap-icon://attachment-zip-file`.
        WHEN `audio/mpeg` OR `audio/voxware` OR `audio/x-aiff` OR `audio/x-midi` OR `audio/x-mpeg` OR `audio/x-m4a`
            OR `audio/x-pn-realaudio` OR `audio/x-pn-realaudio-plugin` OR `audio/x-qt-stream` OR `audio/x-wav`.
          result = `sap-icon://attachment-audio`.
        WHEN `image/png` OR `image/tiff` OR `image/bmp` OR `image/jpeg` OR `image/gif`.
          result = `sap-icon://attachment-photo`.
        WHEN `text/plain` OR `text/comma-separated-values` OR `text/css` OR `text/javascript` OR `text/richtext`
            OR `text/rtf` OR `text/tab-separated-values` OR `text/xml`.
          result = `sap-icon://attachment-text-file`.
        WHEN `video/mpeg` OR `video/mp4` OR `video/quicktime` OR `video/x-msvideo` OR `application/x-shockwave-flash`.
          result = `sap-icon://attachment-video`.
        WHEN OTHERS.
          result = `sap-icon://document`.
      ENDCASE.
      RETURN.
    ENDIF.

    
    dot = find( val = filename sub = `.` occ = -1 ).
    IF dot < 0.
      result = `sap-icon://document`.
      RETURN.
    ENDIF.
    
    extension = to_lower( substring( val = filename off = dot + 1 ) ).
    CASE extension.
      WHEN `bmp` OR `jpg` OR `jpeg` OR `png`.
        result = `sap-icon://card`.
      WHEN `csv` OR `xls` OR `xlsx`.
        result = `sap-icon://excel-attachment`.
      WHEN `doc` OR `docx` OR `odt`.
        result = `sap-icon://doc-attachment`.
      WHEN `pdf`.
        result = `sap-icon://pdf-attachment`.
      WHEN `ppt` OR `pptx`.
        result = `sap-icon://ppt-attachment`.
      WHEN `txt`.
        result = `sap-icon://document-text`.
      WHEN OTHERS.
        result = `sap-icon://document`.
    ENDCASE.

  ENDMETHOD.


  METHOD size_with_units.

    " UploadSetwithTable.getFileSizeWithUnits - KB below a megabyte, then MB, then GB
    CONSTANTS kilobyte TYPE i VALUE 1024.
    DATA temp22 TYPE decfloat34.
    DATA bytes LIKE temp22.
    temp22 = size.
    
    bytes = temp22.
    IF size < kilobyte * kilobyte.
      result = |{ bytes / kilobyte DECIMALS = 2 } KB|.
    ELSEIF size < kilobyte * kilobyte * kilobyte.
      result = |{ bytes / kilobyte / kilobyte DECIMALS = 2 } MB|.
    ELSE.
      result = |{ bytes / kilobyte / kilobyte / kilobyte DECIMALS = 2 } GB|.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " model/documents.json, every row - the document URLs point at the OpenUI5 host
    DATA temp23 LIKE t_items.
    DATA temp24 LIKE LINE OF temp23.
    DATA temp25 LIKE LINE OF t_items.
    DATA row LIKE REF TO temp25.
    CLEAR temp23.
    
    CLEAR temp24.
    temp24-id = `23004569`.
    temp24-filename = `Invoice summary.doc`.
    temp24-mediatype = `application/msword`.
    temp24-imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp24-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Agenda.doc`.
    temp24-revision = `01`.
    temp24-status = `In work`.
    temp24-filesize = 200.
    temp24-lastmodifiedby = `Jane Burns`.
    temp24-lastmodified = `10/03/21, 10:03:00 PM`.
    temp24-documenttype = `Invoice`.
    temp24-previewable = abap_true.
    INSERT temp24 INTO TABLE temp23.
    CLEAR temp24.
    temp24-id = `23004589`.
    temp24-filename = `Business Plan Topics.xls`.
    temp24-mediatype = `application/vnd.ms-excel`.
    temp24-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Topics.xls`.
    temp24-revision = `00`.
    temp24-status = `In work`.
    temp24-filesize = 2400.
    temp24-lastmodifiedby = `Jane Burns`.
    temp24-lastmodified = `10/03/21, 10:03:00 PM`.
    temp24-documenttype = `Invoice`.
    temp24-previewable = abap_true.
    INSERT temp24 INTO TABLE temp23.
    CLEAR temp24.
    temp24-id = `23004578`.
    temp24-filename = `Instructions.pdf`.
    temp24-mediatype = `application/pdf`.
    temp24-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Instructions.pdf`.
    temp24-revision = `01`.
    temp24-status = `In work`.
    temp24-filesize = 30000.
    temp24-lastmodifiedby = `Jane Burns`.
    temp24-lastmodified = `10/03/21, 10:03:00 PM`.
    temp24-documenttype = `Specification`.
    temp24-previewable = abap_true.
    temp24-trustedsource = abap_true.
    INSERT temp24 INTO TABLE temp23.
    CLEAR temp24.
    temp24-id = `23004579`.
    temp24-filename = `Document.txt`.
    temp24-mediatype = `text/plain`.
    temp24-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Document.txt`.
    temp24-revision = `42`.
    temp24-status = `In work`.
    temp24-filesize = 420.
    temp24-lastmodifiedby = `Jane Burns`.
    temp24-lastmodified = `10/03/21, 10:03:00 PM`.
    temp24-documenttype = `Document`.
    temp24-previewable = abap_true.
    INSERT temp24 INTO TABLE temp23.
    CLEAR temp24.
    temp24-id = `23004581`.
    temp24-filename = `Test Image.png`.
    temp24-mediatype = `image/png`.
    temp24-imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp24-url = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp24-revision = `06`.
    temp24-status = `In work`.
    temp24-filesize = 420.
    temp24-lastmodifiedby = `Jane Burns`.
    temp24-lastmodified = `10/03/21, 10:03:00 PM`.
    temp24-documenttype = `Attachment`.
    temp24-previewable = abap_true.
    INSERT temp24 INTO TABLE temp23.
    CLEAR temp24.
    temp24-id = `23004582`.
    temp24-filename = `Test Attachment.gif`.
    temp24-mediatype = `image/gif`.
    temp24-imageurl = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`.
    temp24-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`.
    temp24-revision = `11`.
    temp24-status = `In work`.
    temp24-filesize = 420.
    temp24-lastmodifiedby = `Jane Burns`.
    temp24-lastmodified = `10/03/21, 10:03:00 PM`.
    temp24-documenttype = `Attachment`.
    temp24-previewable = abap_true.
    INSERT temp24 INTO TABLE temp23.
    CLEAR temp24.
    temp24-id = `23004583`.
    temp24-filename = `Test Video.mp4`.
    temp24-mediatype = `video/mp4`.
    temp24-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Video.mp4`.
    temp24-revision = `99`.
    temp24-status = `In work`.
    temp24-filesize = 420000.
    temp24-lastmodifiedby = `Jane Burns`.
    temp24-lastmodified = `10/03/21, 10:03:00 PM`.
    temp24-documenttype = `Attachment`.
    temp24-previewable = abap_true.
    INSERT temp24 INTO TABLE temp23.
    CLEAR temp24.
    temp24-id = `23004590`.
    temp24-filename = `Sample Zip File.zip`.
    temp24-mediatype = `application/zip`.
    temp24-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/sample-zip-file.zip`.
    temp24-revision = `00`.
    temp24-status = `In work`.
    temp24-filesize = 42000.
    temp24-lastmodifiedby = `Jane Burns`.
    temp24-lastmodified = `10/03/22, 10:20:00 PM`.
    temp24-documenttype = `Attachment`.
    temp24-previewable = abap_true.
    INSERT temp24 INTO TABLE temp23.
    CLEAR temp24.
    temp24-id = `23004584`.
    temp24-filename = `Transmission.vds`.
    temp24-mediatype = `model/vnd.sap.vds`.
    temp24-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/transmission.vds`.
    temp24-revision = `42`.
    temp24-status = `In work`.
    temp24-filesize = 123.
    temp24-lastmodifiedby = `Jane Burns`.
    temp24-lastmodified = `10/03/22, 10:20:00 PM`.
    temp24-documenttype = `Attachment`.
    temp24-previewable = abap_true.
    INSERT temp24 INTO TABLE temp23.
    t_items = temp23.
    
    
    LOOP AT t_items REFERENCE INTO row.
      row_derive( CHANGING row = row->* ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
