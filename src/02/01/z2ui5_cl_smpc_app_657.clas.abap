" @keywords uploadsetwithtable upload setwith table sap.m.plugins uploadsetwithtableplugin.responsivetablefilepreview dynamicpage overflowtoolbar title toolbarspacer searchfield overflowtoolbarlayoutdata
" @summary This example showcases how uploaded files can be previewed with FilePreviewDialog control and its related configuration. UploadSetwithTable plugin creates and uses default instance of FilePreviewDialog, if not defined.
" @origin sap.m.sample.UploadSetwithTablePlugin.ResponsiveTableFilePreview - https://sdk.openui5.org/entity/sap.m.plugins.UploadSetwithTable/sample/sap.m.sample.UploadSetwithTablePlugin.ResponsiveTableFilePreview (status: generated)
CLASS z2ui5_cl_smpc_app_657 DEFINITION PUBLIC.

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
    TYPES temp1_2d19d96275 TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
DATA t_items TYPE temp1_2d19d96275.
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
    " the binding paths of the selected rows and of the row a removal asks about
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
    METHODS selection_reset.
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


CLASS z2ui5_cl_smpc_app_657 IMPLEMENTATION.

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
    DATA temp6 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp7 TYPE string_table.
    DATA temp8 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `IMAGEURL` INTO TABLE temp1.
    INSERT `UPLOADSTATE` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `table-uploadSet` INTO TABLE temp2.
    INSERT `items` INTO TABLE temp2.
    INSERT `filter` INTO TABLE temp2.
    INSERT `FILENAME` INTO TABLE temp2.
    INSERT `Contains` INTO TABLE temp2.
    INSERT `${$source>/value}` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `uploadSetPlugin` INTO TABLE temp3.
    INSERT `download` INTO TABLE temp3.
    INSERT `$controller.getView().byId('table-uploadSet').getSelectedContexts()[0]` INTO TABLE temp3.
    INSERT `true` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `uploadSetPlugin` INTO TABLE temp4.
    INSERT `renameItem` INTO TABLE temp4.
    INSERT `$controller.getView().byId('table-uploadSet').getSelectedContexts()[0]` INTO TABLE temp4.
    
    CLEAR temp5.
    INSERT `${$parameters>/item}.getFileName()` INTO TABLE temp5.
    INSERT `${$parameters>/item}.getMediaType()` INTO TABLE temp5.
    INSERT `${$parameters>/item}.getFileObject().size` INTO TABLE temp5.
    
    CLEAR temp6.
    temp6-check_prevent_default = abap_true.
    temp6-check_queue_last = abap_true.
    
    CLEAR temp7.
    INSERT `${$parameters>/item}.getBindingContext().getPath()` INTO TABLE temp7.
    INSERT `${$parameters>/item}.getFileName()` INTO TABLE temp7.
    
    CLEAR temp8.
    INSERT `uploadSetPlugin` INTO TABLE temp8.
    INSERT `openFilePreview` INTO TABLE temp8.
    INSERT `$event.oSource.getBindingContext()` INTO TABLE temp8.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`         v = `sap.m`
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
                    )->a( n = `id`              v = `table-uploadSet`
                    )->a( n = `sticky`          v = `ColumnHeaders,HeaderToolbar`
                    )->a( n = `width`           v = `auto`
                    )->a( n = `mode`            v = `MultiSelect`
                    )->a( n = `fixedLayout`     v = `false`
                    )->a( n = `inset`           v = `true`
                    )->a( n = `autoPopinMode`   v = `true`
                    )->a( n = `hiddenInPopin`   v = `None`
                    " IMAGEURL and UPLOADSTATE stay absent where the mock has
                    " none, so the view's undefined checks read as in the sample
                    )->a( n = `items`           v = |\{ path: '{ client->_bind( val                = t_items
                                                                                path               = abap_true
                                                                                omit_initial_paths = temp1 ) }', templateShareable: false \}|
                    )->a( n = `selectionChange` v = client->_event( val = `SELECTION`
                                                                    arg = `$event.oSource.getSelectedContexts().join()` )

                    )->ele( `headerToolbar`
                        )->ele( `OverflowToolbar`
                            )->tag( `Title`
                                )->a( n = `text`  v = |Documents (\{= ${ client->_bind( t_items ) }.length\})|
                                )->a( n = `level` v = `H2`
                            )->tag( `ToolbarSpacer`

                            )->ele( `SearchField`
                                )->a( n = `width`      v = `20%`
                                )->a( n = `liveChange` v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                                     t_arg = temp2 )

                                )->ele( `layoutData`
                                    )->tag( `OverflowToolbarLayoutData`
                                        )->a( n = `priority` v = `NeverOverflow`

                                )->end(
                            )->end(
                            )->tag( `ToolbarSeparator`
                            )->tag( n = `ActionsPlaceholder` ns = `upload`
                                )->a( n = `id`             v = `uploadButton`
                                )->a( n = `placeholderFor` v = `UploadButtonPlaceholder`
                            )->tag( `Button`
                                )->a( n = `id`      v = `downloadSelectedButton`
                                )->a( n = `text`    v = `Download`
                                )->a( n = `enabled` v = client->_bind( download_enabled )
                                )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                  t_arg = temp3 )

                            )->ele( `MenuButton`
                                )->a( n = `text` v = `Add`

                                )->ele( `menu`
                                    )->ele( `Menu`
                                        )->tag( `MenuItem`
                                            )->a( n = `text`  v = `URL`
                                            )->a( n = `press` v = client->_event( `ADD_URL` )

                                    )->end(
                                )->end(
                                )->ele( `layoutData`
                                    )->tag( `OverflowToolbarLayoutData`
                                        )->a( n = `priority` v = `AlwaysOverflow`

                                )->end(
                            )->end(
                            )->ele( `Button`
                                )->a( n = `id`      v = `removeDocumentButton`
                                )->a( n = `text`    v = `Remove`
                                )->a( n = `press`   v = client->_event( `REMOVE_SELECTED` )
                                )->a( n = `enabled` v = client->_bind( single_enabled )

                                )->ele( `layoutData`
                                    )->tag( `OverflowToolbarLayoutData`
                                        )->a( n = `priority` v = `AlwaysOverflow`

                                )->end(
                            )->end(
                            )->ele( `Button`
                                )->a( n = `id`      v = `renameButton`
                                )->a( n = `enabled` v = client->_bind( single_enabled )
                                )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                  t_arg = temp4 )
                                )->a( n = `text`    v = `Rename`

                                )->ele( `layoutData`
                                    )->tag( `OverflowToolbarLayoutData`
                                        )->a( n = `priority` v = `AlwaysOverflow`

                                )->end(
                            )->end(
                            )->ele( `Button`
                                )->a( n = `id`      v = `editUrlButton`
                                )->a( n = `text`    v = `Edit URL`
                                )->a( n = `enabled` v = client->_bind( single_enabled )
                                )->a( n = `press`   v = client->_event( `EDIT_URL` )

                                )->ele( `layoutData`
                                    )->tag( `OverflowToolbarLayoutData`
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
                                                                                   t_arg  = temp5
                                                                                   s_ctrl = temp6 )
                            )->a( n = `itemRenamed`            v = client->_event( val   = `RENAMED`
                                                                                   t_arg = temp7 )
                            )->a( n = `cloudFilePickerEnabled` v = `true`
                            )->a( n = `actions`                v = `uploadButton`
                            )->a( n = `previewDialog`          v = `FilePreviewDialog`

                            )->ele( n = `rowConfiguration` ns = `plugins`
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
                        )->tag( n = `FilePreviewDialog` ns = `upload`
                            )->a( n = `id`                    v = `FilePreviewDialog`
                            )->a( n = `showCarouselArrows`    v = `true`
                            )->a( n = `maxFileSizeforPreview` v = `50`

                    )->end(
                    )->ele( `columns`
                        )->ele( `Column`
                            )->a( n = `id`         v = `fileName`
                            )->a( n = `importance` v = `High`

                            )->ele( `header`
                                )->tag( `Label`
                                    )->a( n = `text` v = `File Name`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `id` v = `id`

                            )->ele( `header`
                                )->tag( `Label`
                                    )->a( n = `text` v = `ID`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `id` v = `revision`

                            )->ele( `header`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Revision`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `id` v = `status`

                            )->ele( `header`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Status`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `id` v = `fileSize`

                            )->ele( `header`
                                )->tag( `Label`
                                    )->a( n = `text` v = `File Size`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `id` v = `lastModified`

                            )->ele( `header`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Last Modified`

                            )->end(
                        )->end(
                        )->tag( `Column`
                            )->a( n = `id`         v = `actionButton`
                            )->a( n = `importance` v = `High`

                    )->end(
                    )->ele( `items`
                        )->ele( `ColumnListItem`
                            )->a( n = `highlight` v = `{= ${UPLOADSTATE} === 'Complete' ? 'Indication05' : null }`

                            )->ele( `cells`
                                )->ele( `HBox`
                                    )->tag( `Image`
                                        )->a( n = `src`     v = `{IMAGEURL}`
                                        )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`
                                        )->a( n = `visible` v = `{= ${IMAGEURL} !== undefined}`
                                    " getIconSrc runs in ABAP: the row carries the finished icon
                                    )->tag( n = `Icon` ns = `core`
                                        )->a( n = `src`     v = `{ICON}`
                                        )->a( n = `visible` v = `{= ${IMAGEURL} === undefined || ${IMAGEURL} === '' }`
                                        )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`

                                    )->ele( `VBox`
                                        )->a( n = `class` v = `sapUiTinyMargin sapUiSmallMarginBegin`

                                        )->tag( `Link`
                                            )->a( n = `text`  v = `{FILENAME}`
                                            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                            t_arg = temp8 )
                                            )->a( n = `class` v = `sapUiTinyMarginBottom`
                                        )->tag( `Text`
                                            )->a( n = `text` v = `{DOCUMENTTYPE}`

                                    )->end(
                                )->end(
                                )->tag( `Text`
                                    )->a( n = `text` v = `{ID}`
                                )->tag( `Link`
                                    )->a( n = `text` v = `{REVISION}`
                                )->tag( `Text`
                                    )->a( n = `text` v = `{STATUS}`
                                " getFileSizeWithUnits runs in ABAP as well
                                )->tag( `Text`
                                    )->a( n = `text` v = `{FILESIZE_UNITS}`

                                )->ele( `VBox`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{LASTMODIFIEDBY}`
                                    )->tag( `Text`
                                        )->a( n = `class` v = `sapUiTinyMarginTop`
                                        )->a( n = `text`  v = `{LASTMODIFIED}`

                                )->end(
                                )->tag( `Button`
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
        DATA temp1 TYPE xsdboolean.
        DATA temp2 TYPE xsdboolean.
        DATA current TYPE i.
        DATA row LIKE LINE OF t_items.
        FIELD-SYMBOLS <temp5> LIKE LINE OF t_items.
        DATA temp6 LIKE sy-tabix.
          DATA target TYPE i.
            FIELD-SYMBOLS <temp4> LIKE LINE OF t_items.
            DATA temp5 LIKE sy-tabix.
            FIELD-SYMBOLS <temp6> LIKE LINE OF t_items.
            DATA temp7 LIKE sy-tabix.
          FIELD-SYMBOLS <temp8> LIKE LINE OF t_selected.
          DATA temp9 LIKE sy-tabix.
          DATA index TYPE i.
        DATA temp10 TYPE i.
        DATA renamed TYPE i.
          FIELD-SYMBOLS <temp11> LIKE LINE OF t_items.
          DATA temp12 LIKE sy-tabix.

    CASE client->get_event( ).

      WHEN `SELECTION`.
        " onSelectionChange - the selected rows arrive as their binding paths
        IF client->get_event_arg( ) IS INITIAL.
          
          CLEAR temp3.
          t_selected = temp3.
        ELSE.
          SPLIT client->get_event_arg( ) AT `,` INTO TABLE t_selected.
        ENDIF.
        
        temp1 = boolc( t_selected IS NOT INITIAL ).
        download_enabled = temp1.
        
        temp2 = boolc( lines( t_selected ) = 1 ).
        single_enabled   = temp2.

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
        
        
        
        temp6 = sy-tabix.
        READ TABLE t_items INDEX current ASSIGNING <temp5>.
        sy-tabix = temp6.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        row = <temp5>.
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
            
            
            temp5 = sy-tabix.
            READ TABLE t_items INDEX target ASSIGNING <temp4>.
            sy-tabix = temp5.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            <temp4>-filename = name_input.
            
            
            temp7 = sy-tabix.
            READ TABLE t_items INDEX target ASSIGNING <temp6>.
            sy-tabix = temp7.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            <temp6>-url      = url_input.
          ENDIF.
          client->popup_destroy( ).
        ENDIF.

      WHEN `REMOVE_SELECTED`.
        IF t_selected IS NOT INITIAL.
          
          
          temp9 = sy-tabix.
          READ TABLE t_selected INDEX 1 ASSIGNING <temp8>.
          sy-tabix = temp9.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          remove_ask( <temp8> ).
        ENDIF.

      WHEN `REMOVE_ROW`.
        remove_ask( client->get_event_arg( ) ).

      WHEN `REMOVE_CLOSE`.
        IF client->get_event_arg( ) = `Remove`.
          
          index = row_index( remove_path ).
          IF index BETWEEN 1 AND lines( t_items ).
            DELETE t_items INDEX index.
          ENDIF.
          selection_reset( ).
        ENDIF.

      WHEN `UPLOAD`.
        " the file the FileUploader picked, as the mock server would answer it
        
        temp10 = client->get_event_arg( 3 ).
        row_add( filename  = client->get_event_arg( )
                 mediatype = client->get_event_arg( 2 )
                 url       = ``
                 filesize  = temp10 ).
        client->message_toast_display( `Document Added` ).

      WHEN `RENAMED`.
        " onDocumentRenamedSuccess writes the new name into the row
        
        renamed = row_index( client->get_event_arg( ) ).
        IF renamed BETWEEN 1 AND lines( t_items ).
          
          
          temp12 = sy-tabix.
          READ TABLE t_items INDEX renamed ASSIGNING <temp11>.
          sy-tabix = temp12.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp11>-filename = client->get_event_arg( 2 ).
        ENDIF.
        client->message_toast_display( text = `Document Renamed.` duration = `2000` ).

    ENDCASE.

  ENDMETHOD.


  METHOD url_apply.
        DATA temp13 TYPE string_table.
    DATA has_error TYPE abap_bool.
    DATA temp3 TYPE xsdboolean.

    " handleAddViaUrl
    IF is_edit = abap_true.
      IF name_valid( ) = abap_true.
        " showEditConfirmation - a Message dialog in the Warning state
        
        CLEAR temp13.
        INSERT `Save` INTO TABLE temp13.
        INSERT `DiscardChanges` INTO TABLE temp13.
        client->message_box_display( text             = `You have made changes to this object. What would you like to do?`
                                     type             = `warning`
                                     title            = `Warning`
                                     actions          = temp13
                                     emphasizedaction = `Save`
                                     onclose          = `EDIT_CONFIRM` ).
      ELSE.
        client->message_toast_display( `No Changes found` ).
      ENDIF.
      RETURN.
    ENDIF.
    
    
    temp3 = boolc( name_valid( ) = abap_false ).
    has_error = temp3.
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
    DATA temp15 TYPE string_table.
    FIELD-SYMBOLS <temp7> LIKE LINE OF t_items.
    DATA temp8 LIKE sy-tabix.
    index = row_index( path ).
    IF index NOT BETWEEN 1 AND lines( t_items ).
      RETURN.
    ENDIF.
    remove_path = path.
    
    CLEAR temp15.
    INSERT `Remove` INTO TABLE temp15.
    INSERT `CANCEL` INTO TABLE temp15.
    
    
    temp8 = sy-tabix.
    READ TABLE t_items INDEX index ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    client->message_box_display( text             = |Are you sure you want to remove the document { <temp7>-filename } ?|
                                 type             = `warning`
                                 actions          = temp15
                                 emphasizedaction = `Remove`
                                 styleclass       = `sapMUSTRemovePopoverContainer`
                                 initialfocus     = `CANCEL`
                                 onclose          = `REMOVE_CLOSE` ).

  ENDMETHOD.


  METHOD selection_reset.

    " oTable.removeSelections( ) - and the buttons follow the empty selection
    DATA temp17 TYPE string_table.
    DATA temp19 TYPE string_table.
    CLEAR temp17.
    INSERT `table-uploadSet` INTO TABLE temp17.
    INSERT `removeSelections` INTO TABLE temp17.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp17 ).
    
    CLEAR temp19.
    t_selected       = temp19.
    download_enabled = abap_false.
    single_enabled   = abap_false.

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
    DATA temp20 TYPE ty_s_item.
    DATA row LIKE temp20.

    " the mock server's Create branch - unshift the new document
    upload_no = upload_no + 1.
    
    CLEAR temp20.
    temp20-id = |{ upload_no }|.
    temp20-filename = filename.
    temp20-mediatype = mediatype.
    temp20-url = url.
    temp20-uploadstate = `Complete`.
    temp20-revision = `00`.
    temp20-status = `In work`.
    temp20-filesize = filesize.
    temp20-lastmodifiedby = `Jane Burns`.
    temp20-lastmodified = `10/03/21, 10:03:00 PM`.
    temp20-documenttype = `Invoice`.
    temp20-trustedsource = abap_true.
    
    row = temp20.
    row_derive( CHANGING row = row ).
    INSERT row INTO t_items INDEX 1.

  ENDMETHOD.


  METHOD selected_index.
    FIELD-SYMBOLS <temp21> LIKE LINE OF t_selected.
    DATA temp22 LIKE sy-tabix.

    " the one selected row the toolbar actions work on - 0 when there is none
    IF t_selected IS INITIAL.
      RETURN.
    ENDIF.
    
    
    temp22 = sy-tabix.
    READ TABLE t_selected INDEX 1 ASSIGNING <temp21>.
    sy-tabix = temp22.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    result = row_index( <temp21> ).
    IF result > lines( t_items ).
      result = 0.
    ENDIF.

  ENDMETHOD.


  METHOD row_index.

    " a row's binding path ends in its 0-based index: /T_ITEMS/3 is the 4th row
    DATA slash TYPE i.
    DATA digits TYPE string.
    DATA temp23 TYPE i.
    slash = find( val = path sub = `/` occ = -1 ).
    IF slash < 0.
      RETURN.
    ENDIF.
    
    digits = substring( val = path off = slash + 1 ).
    IF digits IS INITIAL OR digits CN `0123456789`.
      RETURN.
    ENDIF.
    
    temp23 = digits.
    result = temp23 + 1.

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
    DATA temp24 TYPE decfloat34.
    DATA bytes LIKE temp24.
    temp24 = size.
    
    bytes = temp24.
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
    DATA temp25 LIKE t_items.
    DATA temp26 LIKE LINE OF temp25.
    DATA temp27 LIKE LINE OF t_items.
    DATA row LIKE REF TO temp27.
    CLEAR temp25.
    
    CLEAR temp26.
    temp26-id = `23004569`.
    temp26-filename = `Invoice summary.doc`.
    temp26-mediatype = `application/msword`.
    temp26-imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp26-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Agenda.doc`.
    temp26-revision = `01`.
    temp26-status = `In work`.
    temp26-filesize = 200.
    temp26-lastmodifiedby = `Jane Burns`.
    temp26-lastmodified = `10/03/21, 10:03:00 PM`.
    temp26-documenttype = `Invoice`.
    temp26-previewable = abap_true.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-id = `23004589`.
    temp26-filename = `Business Plan Topics.xls`.
    temp26-mediatype = `application/vnd.ms-excel`.
    temp26-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Topics.xls`.
    temp26-revision = `00`.
    temp26-status = `In work`.
    temp26-filesize = 2400.
    temp26-lastmodifiedby = `Jane Burns`.
    temp26-lastmodified = `10/03/21, 10:03:00 PM`.
    temp26-documenttype = `Invoice`.
    temp26-previewable = abap_true.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-id = `23004578`.
    temp26-filename = `Instructions.pdf`.
    temp26-mediatype = `application/pdf`.
    temp26-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Instructions.pdf`.
    temp26-revision = `01`.
    temp26-status = `In work`.
    temp26-filesize = 30000.
    temp26-lastmodifiedby = `Jane Burns`.
    temp26-lastmodified = `10/03/21, 10:03:00 PM`.
    temp26-documenttype = `Specification`.
    temp26-previewable = abap_true.
    temp26-trustedsource = abap_true.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-id = `23004579`.
    temp26-filename = `Document.txt`.
    temp26-mediatype = `text/plain`.
    temp26-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Document.txt`.
    temp26-revision = `42`.
    temp26-status = `In work`.
    temp26-filesize = 420.
    temp26-lastmodifiedby = `Jane Burns`.
    temp26-lastmodified = `10/03/21, 10:03:00 PM`.
    temp26-documenttype = `Document`.
    temp26-previewable = abap_true.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-id = `23004581`.
    temp26-filename = `Test Image.png`.
    temp26-mediatype = `image/png`.
    temp26-imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp26-url = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp26-revision = `06`.
    temp26-status = `In work`.
    temp26-filesize = 420.
    temp26-lastmodifiedby = `Jane Burns`.
    temp26-lastmodified = `10/03/21, 10:03:00 PM`.
    temp26-documenttype = `Attachment`.
    temp26-previewable = abap_true.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-id = `23004582`.
    temp26-filename = `Test Attachment.gif`.
    temp26-mediatype = `image/gif`.
    temp26-imageurl = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`.
    temp26-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`.
    temp26-revision = `11`.
    temp26-status = `In work`.
    temp26-filesize = 420.
    temp26-lastmodifiedby = `Jane Burns`.
    temp26-lastmodified = `10/03/21, 10:03:00 PM`.
    temp26-documenttype = `Attachment`.
    temp26-previewable = abap_true.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-id = `23004583`.
    temp26-filename = `Test Video.mp4`.
    temp26-mediatype = `video/mp4`.
    temp26-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Video.mp4`.
    temp26-revision = `99`.
    temp26-status = `In work`.
    temp26-filesize = 420000.
    temp26-lastmodifiedby = `Jane Burns`.
    temp26-lastmodified = `10/03/21, 10:03:00 PM`.
    temp26-documenttype = `Attachment`.
    temp26-previewable = abap_true.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-id = `23004590`.
    temp26-filename = `Sample Zip File.zip`.
    temp26-mediatype = `application/zip`.
    temp26-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/sample-zip-file.zip`.
    temp26-revision = `00`.
    temp26-status = `In work`.
    temp26-filesize = 42000.
    temp26-lastmodifiedby = `Jane Burns`.
    temp26-lastmodified = `10/03/22, 10:20:00 PM`.
    temp26-documenttype = `Attachment`.
    temp26-previewable = abap_true.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-id = `23004584`.
    temp26-filename = `Transmission.vds`.
    temp26-mediatype = `model/vnd.sap.vds`.
    temp26-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/transmission.vds`.
    temp26-revision = `42`.
    temp26-status = `In work`.
    temp26-filesize = 123.
    temp26-lastmodifiedby = `Jane Burns`.
    temp26-lastmodified = `10/03/22, 10:20:00 PM`.
    temp26-documenttype = `Attachment`.
    temp26-previewable = abap_true.
    INSERT temp26 INTO TABLE temp25.
    t_items = temp25.
    
    
    LOOP AT t_items REFERENCE INTO row.
      row_derive( CHANGING row = row->* ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
