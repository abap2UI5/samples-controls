" @keywords uploadsetwithtable upload setwith table sap.m.plugins uploadsetwithtableplugin.treetablesimple dynamicpage treetable overflowtoolbar title toolbarspacer actionsplaceholder
" @summary This example demonstrates the usage of UploadSetwithTable plugin for tree table with the features of upload, download, drag & drop, remove and rename of files. It also demonstrates how the uploaded files can be displayed in a table.
" @origin sap.m.sample.UploadSetwithTablePlugin.TreeTableSimple - https://sdk.openui5.org/entity/sap.m.plugins.UploadSetwithTable/sample/sap.m.sample.UploadSetwithTablePlugin.TreeTableSimple (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_660 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " documents.json is a folder tree three levels deep - one row type per level,
    " every level carrying every field, the upper two their ITEMS
    TYPES:
      BEGIN OF ty_s_item,
        id             TYPE string,
        filename       TYPE string,
        mediatype      TYPE string,
        imageurl       TYPE string,
        url            TYPE string,
        status         TYPE string,
        filesize       TYPE i,
        lastmodifiedby TYPE string,
        lastmodified   TYPE string,
        documenttype   TYPE string,
        previewable    TYPE abap_bool,
        trustedsource  TYPE abap_bool,
        isdirectory    TYPE abap_bool,
        color          TYPE string,
        bgcolor        TYPE string,
        uploadstate    TYPE string,
        icon           TYPE string,
        filesize_units TYPE string,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_folder,
        id             TYPE string,
        filename       TYPE string,
        mediatype      TYPE string,
        imageurl       TYPE string,
        url            TYPE string,
        status         TYPE string,
        filesize       TYPE i,
        lastmodifiedby TYPE string,
        lastmodified   TYPE string,
        documenttype   TYPE string,
        previewable    TYPE abap_bool,
        trustedsource  TYPE abap_bool,
        isdirectory    TYPE abap_bool,
        color          TYPE string,
        bgcolor        TYPE string,
        uploadstate    TYPE string,
        icon           TYPE string,
        filesize_units TYPE string,
        items          TYPE ty_t_item,
      END OF ty_s_folder.
    TYPES ty_t_folder TYPE STANDARD TABLE OF ty_s_folder WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_root,
        id             TYPE string,
        filename       TYPE string,
        mediatype      TYPE string,
        imageurl       TYPE string,
        url            TYPE string,
        status         TYPE string,
        filesize       TYPE i,
        lastmodifiedby TYPE string,
        lastmodified   TYPE string,
        documenttype   TYPE string,
        previewable    TYPE abap_bool,
        trustedsource  TYPE abap_bool,
        isdirectory    TYPE abap_bool,
        color          TYPE string,
        bgcolor        TYPE string,
        uploadstate    TYPE string,
        icon           TYPE string,
        filesize_units TYPE string,
        items          TYPE ty_t_folder,
      END OF ty_s_root.
    TYPES temp1_94db705a1f TYPE STANDARD TABLE OF ty_s_root WITH DEFAULT KEY.
DATA t_items TYPE temp1_94db705a1f.
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
    TYPES ty_t_index TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

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
    METHODS path_indices
      IMPORTING
        path          TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_index.
    METHODS node_get
      IMPORTING
        path          TYPE string
      RETURNING
        VALUE(result) TYPE ty_s_item.
    METHODS node_rename
      IMPORTING
        path TYPE string
        name TYPE string.
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


CLASS z2ui5_cl_smpc_app_660 IMPLEMENTATION.

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
                )->ele( `TreeTable`
                    )->a( n = `id`                 v = `table-uploadSet`
                    " IMAGEURL and UPLOADSTATE stay absent where the mock has
                    " none, so the view's undefined checks read as in the sample
                    )->a( n = `rows`               v = client->_bind( val                = t_items
                                                                      omit_initial_paths = temp1 )
                    )->a( n = `selectionMode`      v = `MultiToggle`
                    )->a( n = `rowSelectionChange` v = client->_event( val = `SELECTION`
                                                                       arg = `$event.oSource.getBinding('rows').getSelectedContexts().join()` )

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
                                )->a( n = `isDirectoryPath`     v = `ISDIRECTORY`

                        )->end(
                    )->end(
                    )->ele( `rowSettingsTemplate`
                        )->tag( `RowSettings`
                            )->a( n = `highlight` v = `{= ${UPLOADSTATE} === 'Complete' ? 'Indication05' : null }`

                    )->end(
                    )->ele( `columns`
                        )->ele( `Column`
                            )->a( n = `width` v = `40%`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `File Name`

                            )->ele( `template`
                                )->ele( n = `HBox` ns = `m`
                                    )->a( n = `class` v = `sapUiSmallMarginTop sapUiTinyMarginBottom`

                                    )->tag( n = `Image` ns = `m`
                                        )->a( n = `src`     v = `{IMAGEURL}`
                                        )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`
                                        )->a( n = `visible` v = `{= ${IMAGEURL} !== undefined}`
                                    " getIconSrc runs in ABAP: the row carries the finished icon
                                    )->tag( n = `Icon` ns = `core`
                                        )->a( n = `src`             v = `{ICON}`
                                        )->a( n = `visible`         v = `{= ${IMAGEURL} === undefined || ${IMAGEURL} === '' }`
                                        )->a( n = `class`           v = `sapMUSTItemIcon`
                                        )->a( n = `color`           v = `{= ${ISDIRECTORY} ? ${COLOR} : '' }`
                                        )->a( n = `backgroundColor` v = `{= ${ISDIRECTORY} ? ${BGCOLOR} : '' }`

                                    )->ele( n = `VBox` ns = `m`
                                        )->a( n = `class` v = `sapUiTinyMargin sapUiSmallMarginBegin`

                                        )->tag( n = `Text` ns = `m`
                                            )->a( n = `text`    v = `{FILENAME}`
                                            )->a( n = `class`   v = `sapUiSmallMarginBottom`
                                            )->a( n = `visible` v = `{= ${ISDIRECTORY} === true }`
                                        )->tag( n = `Link` ns = `m`
                                            )->a( n = `text`    v = `{FILENAME}`
                                            )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                              t_arg = temp9 )
                                            )->a( n = `class`   v = `sapUiTinyMarginBottom`
                                            )->a( n = `visible` v = `{= ${ISDIRECTORY} === false }`
                                        )->tag( n = `Text` ns = `m`
                                            )->a( n = `text` v = `{DOCUMENTTYPE}`

                                    )->end(
                                )->end(
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
                                    )->a( n = `class`   v = `sapUiTinyMarginBegin`
                                    )->a( n = `type`    v = `Transparent`
                                    )->a( n = `icon`    v = `sap-icon://decline`
                                    )->a( n = `press`   v = client->_event( val = `REMOVE_ROW`
                                                                            arg = `$event.oSource.getBindingContext().getPath()` )
                                    )->a( n = `visible` v = `{= ${ISDIRECTORY} === false }` ).

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
        DATA files TYPE i.
        DATA folders TYPE i.
        DATA path LIKE LINE OF t_selected.
        DATA temp1 TYPE xsdboolean.
        DATA temp2 TYPE xsdboolean.
        DATA row TYPE z2ui5_cl_smpc_app_660=>ty_s_item.
        FIELD-SYMBOLS <temp4> LIKE LINE OF t_selected.
        DATA temp5 LIKE sy-tabix.
            DATA edit_id TYPE z2ui5_cl_smpc_app_660=>ty_s_item-id.
            FIELD-SYMBOLS <temp6> LIKE LINE OF t_selected.
            DATA temp7 LIKE sy-tabix.
            DATA temp4 LIKE LINE OF t_items.
            DATA top LIKE REF TO temp4.
          FIELD-SYMBOLS <temp5> LIKE LINE OF t_selected.
          DATA temp6 LIKE sy-tabix.
          DATA levels TYPE z2ui5_cl_smpc_app_660=>ty_t_index.
          FIELD-SYMBOLS <temp7> LIKE LINE OF levels.
          DATA temp8 LIKE sy-tabix.
            FIELD-SYMBOLS <temp9> LIKE LINE OF levels.
            DATA temp10 LIKE sy-tabix.
        DATA temp11 TYPE i.

    CASE client->get_event( ).

      WHEN `SELECTION`.
        " onSelectionChange - the binding's selected contexts arrive as their paths;
        " the buttons only count files, and only while no folder is selected
        
        CLEAR temp3.
        t_selected = temp3.
        IF client->get_event_arg( ) IS NOT INITIAL.
          SPLIT client->get_event_arg( ) AT `,` INTO TABLE t_selected.
        ENDIF.
        
        files   = 0.
        
        folders = 0.
        
        LOOP AT t_selected INTO path.
          IF node_get( path )-isdirectory = abap_true.
            folders = folders + 1.
          ELSE.
            files = files + 1.
          ENDIF.
        ENDLOOP.
        
        temp1 = boolc( files > 0 AND folders = 0 ).
        download_enabled = temp1.
        
        temp2 = boolc( files = 1 AND folders = 0 ).
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
        IF t_selected IS INITIAL.
          RETURN.
        ENDIF.
        
        
        
        temp5 = sy-tabix.
        READ TABLE t_selected INDEX 1 ASSIGNING <temp4>.
        sy-tabix = temp5.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        row = node_get( <temp4> ).
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
          " the sample looks the row up by id in the top-level /items only
          IF t_selected IS NOT INITIAL.
            
            
            
            temp7 = sy-tabix.
            READ TABLE t_selected INDEX 1 ASSIGNING <temp6>.
            sy-tabix = temp7.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            edit_id = node_get( <temp6> )-id.
            
            
            LOOP AT t_items REFERENCE INTO top WHERE id = edit_id AND id IS NOT INITIAL.
              top->filename = name_input.
              top->url      = url_input.
            ENDLOOP.
          ENDIF.
          client->popup_destroy( ).
        ENDIF.

      WHEN `REMOVE_SELECTED`.
        IF t_selected IS NOT INITIAL.
          
          
          temp6 = sy-tabix.
          READ TABLE t_selected INDEX 1 ASSIGNING <temp5>.
          sy-tabix = temp6.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          remove_ask( <temp5> ).
        ENDIF.

      WHEN `REMOVE_ROW`.
        remove_ask( client->get_event_arg( ) ).

      WHEN `REMOVE_CLOSE`.
        " removeItem splices the TOP-LEVEL index of the path (split('/')[2]) out of
        " /items - for a file inside a folder, that is its top-level folder
        IF client->get_event_arg( ) = `Remove`.
          
          levels = path_indices( remove_path ).
          
          
          temp8 = sy-tabix.
          READ TABLE levels INDEX 1 ASSIGNING <temp7>.
          sy-tabix = temp8.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          IF levels IS NOT INITIAL AND <temp7> <= lines( t_items ).
            
            
            temp10 = sy-tabix.
            READ TABLE levels INDEX 1 ASSIGNING <temp9>.
            sy-tabix = temp10.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            DELETE t_items INDEX <temp9>.
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
        " onDocumentRenamedSuccess writes the new name into the row, at any depth
        node_rename( path = client->get_event_arg( ) name = client->get_event_arg( 2 ) ).
        client->message_toast_display( text = `Document Renamed.` duration = `2000` ).

    ENDCASE.

  ENDMETHOD.


  METHOD url_apply.
        DATA temp12 TYPE string_table.
    DATA has_error TYPE abap_bool.
    DATA temp3 TYPE xsdboolean.

    " handleAddViaUrl
    IF is_edit = abap_true.
      IF name_valid( ) = abap_true.
        " showEditConfirmation - a Message dialog in the Warning state
        
        CLEAR temp12.
        INSERT `Save` INTO TABLE temp12.
        INSERT `DiscardChanges` INTO TABLE temp12.
        client->message_box_display( text             = `You have made changes to this object. What would you like to do?`
                                     type             = `warning`
                                     title            = `Warning`
                                     actions          = temp12
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
    DATA node TYPE z2ui5_cl_smpc_app_660=>ty_s_item.
    DATA temp14 TYPE string_table.
    node = node_get( path ).
    IF node IS INITIAL.
      RETURN.
    ENDIF.
    remove_path = path.
    
    CLEAR temp14.
    INSERT `Remove` INTO TABLE temp14.
    INSERT `CANCEL` INTO TABLE temp14.
    client->message_box_display( text             = |Are you sure you want to remove the document { node-filename } ?|
                                 type             = `warning`
                                 actions          = temp14
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
    DATA temp16 TYPE ty_s_root.
    DATA row LIKE temp16.

    " the mock server's Create branch - unshift the new document
    upload_no = upload_no + 1.
    
    CLEAR temp16.
    temp16-id = |{ upload_no }|.
    temp16-filename = filename.
    temp16-mediatype = mediatype.
    temp16-url = url.
    temp16-uploadstate = `Complete`.
    temp16-status = `In work`.
    temp16-filesize = filesize.
    temp16-lastmodifiedby = `Jane Burns`.
    temp16-lastmodified = `10/03/21, 10:03:00 PM`.
    temp16-documenttype = `Invoice`.
    temp16-trustedsource = abap_true.
    
    row = temp16.
    row-icon           = icon_for( mediatype = row-mediatype filename = row-filename ).
    row-filesize_units = size_with_units( row-filesize ).
    INSERT row INTO t_items INDEX 1.

  ENDMETHOD.


  METHOD path_indices.

    " a row's binding path holds its index on every level, 0-based:
    " /T_ITEMS/0/ITEMS/1 is the 2nd child of the 1st row
    TYPES temp2 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA parts TYPE temp2.
    DATA part LIKE LINE OF parts.
        DATA temp17 LIKE LINE OF result.
        DATA temp8 LIKE LINE OF result.
    SPLIT path AT `/` INTO TABLE parts.
    
    LOOP AT parts INTO part.
      IF part IS NOT INITIAL AND part CO `0123456789`.
        
        temp17 = part.
        
        temp8 = temp17 + 1.
        INSERT temp8 INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD node_get.

    DATA levels TYPE z2ui5_cl_smpc_app_660=>ty_t_index.
    FIELD-SYMBOLS <temp18> LIKE LINE OF levels.
    DATA temp19 LIKE sy-tabix.
    DATA root LIKE LINE OF t_items.
    FIELD-SYMBOLS <temp9> LIKE LINE OF t_items.
    DATA temp10 LIKE sy-tabix.
    FIELD-SYMBOLS <temp6> LIKE LINE OF levels.
    DATA temp7 LIKE sy-tabix.
    FIELD-SYMBOLS <temp20> LIKE LINE OF levels.
    DATA temp21 LIKE sy-tabix.
    DATA folder TYPE z2ui5_cl_smpc_app_660=>ty_s_folder.
    FIELD-SYMBOLS <temp11> LIKE LINE OF root-items.
    DATA temp12 LIKE sy-tabix.
    FIELD-SYMBOLS <temp8> LIKE LINE OF levels.
    DATA temp9 LIKE sy-tabix.
    FIELD-SYMBOLS <temp22> LIKE LINE OF levels.
    DATA temp23 LIKE sy-tabix.
      FIELD-SYMBOLS <temp24> LIKE LINE OF folder-items.
      DATA temp25 LIKE sy-tabix.
      FIELD-SYMBOLS <temp13> LIKE LINE OF levels.
      DATA temp14 LIKE sy-tabix.
    levels = path_indices( path ).
    
    
    temp19 = sy-tabix.
    READ TABLE levels INDEX 1 ASSIGNING <temp18>.
    sy-tabix = temp19.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF levels IS INITIAL OR <temp18> > lines( t_items ).
      RETURN.
    ENDIF.
    
    
    
    temp10 = sy-tabix.
    
    
    temp7 = sy-tabix.
    READ TABLE levels INDEX 1 ASSIGNING <temp6>.
    sy-tabix = temp7.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    READ TABLE t_items INDEX <temp6> ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    root = <temp9>.
    IF lines( levels ) = 1.
      MOVE-CORRESPONDING root TO result.
      RETURN.
    ENDIF.
    
    
    temp21 = sy-tabix.
    READ TABLE levels INDEX 2 ASSIGNING <temp20>.
    sy-tabix = temp21.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF <temp20> > lines( root-items ).
      RETURN.
    ENDIF.
    
    
    
    temp12 = sy-tabix.
    
    
    temp9 = sy-tabix.
    READ TABLE levels INDEX 2 ASSIGNING <temp8>.
    sy-tabix = temp9.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    READ TABLE root-items INDEX <temp8> ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    folder = <temp11>.
    IF lines( levels ) = 2.
      MOVE-CORRESPONDING folder TO result.
      RETURN.
    ENDIF.
    
    
    temp23 = sy-tabix.
    READ TABLE levels INDEX 3 ASSIGNING <temp22>.
    sy-tabix = temp23.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF <temp22> <= lines( folder-items ).
      
      
      temp25 = sy-tabix.
      
      
      temp14 = sy-tabix.
      READ TABLE levels INDEX 3 ASSIGNING <temp13>.
      sy-tabix = temp14.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      READ TABLE folder-items INDEX <temp13> ASSIGNING <temp24>.
      sy-tabix = temp25.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      result = <temp24>.
    ENDIF.

  ENDMETHOD.


  METHOD node_rename.

    DATA levels TYPE z2ui5_cl_smpc_app_660=>ty_t_index.
    FIELD-SYMBOLS <temp26> LIKE LINE OF levels.
    DATA temp27 LIKE sy-tabix.
    FIELD-SYMBOLS <temp28> TYPE z2ui5_cl_smpc_app_660=>ty_s_root.
    FIELD-SYMBOLS <temp8> LIKE LINE OF levels.
    DATA temp9 LIKE sy-tabix.
DATA root LIKE REF TO <temp28>.
    FIELD-SYMBOLS <temp29> LIKE LINE OF levels.
    DATA temp30 LIKE sy-tabix.
    FIELD-SYMBOLS <temp31> TYPE z2ui5_cl_smpc_app_660=>ty_s_folder.
    FIELD-SYMBOLS <temp10> LIKE LINE OF levels.
    DATA temp11 LIKE sy-tabix.
DATA folder LIKE REF TO <temp31>.
    FIELD-SYMBOLS <temp32> LIKE LINE OF levels.
    DATA temp33 LIKE sy-tabix.
      FIELD-SYMBOLS <temp34> LIKE LINE OF folder->items.
      DATA temp35 LIKE sy-tabix.
      FIELD-SYMBOLS <temp15> LIKE LINE OF levels.
      DATA temp16 LIKE sy-tabix.
    levels = path_indices( path ).
    
    
    temp27 = sy-tabix.
    READ TABLE levels INDEX 1 ASSIGNING <temp26>.
    sy-tabix = temp27.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF levels IS INITIAL OR <temp26> > lines( t_items ).
      RETURN.
    ENDIF.
    
    
    
    temp9 = sy-tabix.
    READ TABLE levels INDEX 1 ASSIGNING <temp8>.
    sy-tabix = temp9.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    READ TABLE t_items INDEX <temp8> ASSIGNING <temp28>.
IF sy-subrc <> 0.
  ASSERT 1 = 0.
ENDIF.

GET REFERENCE OF <temp28> INTO root.
    IF lines( levels ) = 1.
      root->filename = name.
      RETURN.
    ENDIF.
    
    
    temp30 = sy-tabix.
    READ TABLE levels INDEX 2 ASSIGNING <temp29>.
    sy-tabix = temp30.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF <temp29> > lines( root->items ).
      RETURN.
    ENDIF.
    
    
    
    temp11 = sy-tabix.
    READ TABLE levels INDEX 2 ASSIGNING <temp10>.
    sy-tabix = temp11.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    READ TABLE root->items INDEX <temp10> ASSIGNING <temp31>.
IF sy-subrc <> 0.
  ASSERT 1 = 0.
ENDIF.

GET REFERENCE OF <temp31> INTO folder.
    IF lines( levels ) = 2.
      folder->filename = name.
      RETURN.
    ENDIF.
    
    
    temp33 = sy-tabix.
    READ TABLE levels INDEX 3 ASSIGNING <temp32>.
    sy-tabix = temp33.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF <temp32> <= lines( folder->items ).
      
      
      temp35 = sy-tabix.
      
      
      temp16 = sy-tabix.
      READ TABLE levels INDEX 3 ASSIGNING <temp15>.
      sy-tabix = temp16.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      READ TABLE folder->items INDEX <temp15> ASSIGNING <temp34>.
      sy-tabix = temp35.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      <temp34>-filename = name.
    ENDIF.

  ENDMETHOD.


  METHOD row_derive.

    " getIconSrc shows a folder for a directory; a folder has no fileSize, so
    " getFileSizeWithUnits leaves its cell empty
    IF row-isdirectory = abap_true.
      row-icon = `sap-icon://folder-full`.
      RETURN.
    ENDIF.
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
    DATA temp36 TYPE decfloat34.
    DATA bytes LIKE temp36.
    temp36 = size.
    
    bytes = temp36.
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
    DATA temp37 LIKE t_items.
    DATA temp38 LIKE LINE OF temp37.
    DATA temp17 TYPE z2ui5_cl_smpc_app_660=>ty_t_folder.
    DATA temp18 LIKE LINE OF temp17.
    DATA temp10 TYPE z2ui5_cl_smpc_app_660=>ty_t_item.
    DATA temp11 LIKE LINE OF temp10.
    DATA temp19 TYPE z2ui5_cl_smpc_app_660=>ty_t_folder.
    DATA temp20 LIKE LINE OF temp19.
    DATA temp39 LIKE LINE OF t_items.
    DATA root LIKE REF TO temp39.
      DATA temp40 TYPE ty_s_item.
      DATA root_item LIKE temp40.
      DATA temp41 LIKE LINE OF root->items.
      DATA folder LIKE REF TO temp41.
        DATA temp42 TYPE ty_s_item.
        DATA folder_item LIKE temp42.
        DATA temp43 LIKE LINE OF folder->items.
        DATA item LIKE REF TO temp43.
    CLEAR temp37.
    
    CLEAR temp38.
    temp38-filename = `Documents`.
    temp38-isdirectory = abap_true.
    temp38-color = `#ffffff`.
    temp38-bgcolor = `#30914c`.
    
    CLEAR temp17.
    
    CLEAR temp18.
    temp18-id = `23004579`.
    temp18-filename = `Document.txt`.
    temp18-mediatype = `text/plain`.
    temp18-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Document.txt`.
    temp18-status = `In work`.
    temp18-filesize = 420.
    temp18-lastmodifiedby = `Jane Burns`.
    temp18-lastmodified = `10/03/21, 10:03:00 PM`.
    temp18-documenttype = `Document`.
    temp18-previewable = abap_true.
    temp18-isdirectory = abap_false.
    INSERT temp18 INTO TABLE temp17.
    CLEAR temp18.
    temp18-filename = `Invoices`.
    temp18-isdirectory = abap_true.
    temp18-color = `#ffffff`.
    temp18-bgcolor = `#30914c`.
    
    CLEAR temp10.
    
    temp11-id = `23004569`.
    temp11-filename = `Invoice summary.doc`.
    temp11-mediatype = `application/msword`.
    temp11-imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp11-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Agenda.doc`.
    temp11-status = `In work`.
    temp11-filesize = 200.
    temp11-lastmodifiedby = `Jane Burns`.
    temp11-lastmodified = `10/03/21, 10:03:00 PM`.
    temp11-documenttype = `Invoice`.
    temp11-previewable = abap_true.
    temp11-isdirectory = abap_false.
    INSERT temp11 INTO TABLE temp10.
    temp18-items = temp10.
    INSERT temp18 INTO TABLE temp17.
    temp38-items = temp17.
    INSERT temp38 INTO TABLE temp37.
    CLEAR temp38.
    temp38-id = `23004583`.
    temp38-filename = `Test Video.mp4`.
    temp38-mediatype = `video/mp4`.
    temp38-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Video.mp4`.
    temp38-status = `In work`.
    temp38-filesize = 420000.
    temp38-lastmodifiedby = `Jane Burns`.
    temp38-lastmodified = `10/03/21, 10:03:00 PM`.
    temp38-documenttype = `Attachment`.
    temp38-previewable = abap_true.
    temp38-isdirectory = abap_false.
    INSERT temp38 INTO TABLE temp37.
    CLEAR temp38.
    temp38-id = `23004590`.
    temp38-filename = `Sample Zip File.zip`.
    temp38-mediatype = `application/zip`.
    temp38-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/sample-zip-file.zip`.
    temp38-status = `In work`.
    temp38-filesize = 42000.
    temp38-lastmodifiedby = `Jane Burns`.
    temp38-lastmodified = `10/03/22, 10:20:00 PM`.
    temp38-documenttype = `Attachment`.
    temp38-previewable = abap_true.
    temp38-isdirectory = abap_false.
    INSERT temp38 INTO TABLE temp37.
    CLEAR temp38.
    temp38-filename = `Attachments`.
    temp38-isdirectory = abap_true.
    temp38-color = `#ffffff`.
    temp38-bgcolor = `#e76500`.
    
    CLEAR temp19.
    
    temp20-id = `23004578`.
    temp20-filename = `Instructions.pdf`.
    temp20-mediatype = `application/pdf`.
    temp20-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Instructions.pdf`.
    temp20-status = `In work`.
    temp20-filesize = 30000.
    temp20-lastmodifiedby = `Jane Burns`.
    temp20-lastmodified = `10/03/21, 10:03:00 PM`.
    temp20-documenttype = `Specification`.
    temp20-previewable = abap_true.
    temp20-trustedsource = abap_true.
    temp20-isdirectory = abap_false.
    INSERT temp20 INTO TABLE temp19.
    temp38-items = temp19.
    INSERT temp38 INTO TABLE temp37.
    CLEAR temp38.
    temp38-id = `23004584`.
    temp38-filename = `Transmission.vds`.
    temp38-mediatype = `model/vnd.sap.vds`.
    temp38-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/transmission.vds`.
    temp38-status = `In work`.
    temp38-filesize = 123.
    temp38-lastmodifiedby = `Jane Burns`.
    temp38-lastmodified = `10/03/22, 10:20:00 PM`.
    temp38-documenttype = `Attachment`.
    temp38-previewable = abap_true.
    temp38-trustedsource = abap_true.
    temp38-isdirectory = abap_false.
    INSERT temp38 INTO TABLE temp37.
    t_items = temp37.
    " the derived ICON and FILESIZE_UNITS on every level
    
    
    LOOP AT t_items REFERENCE INTO root.
      
      CLEAR temp40.
      MOVE-CORRESPONDING root->* TO temp40.
      
      root_item = temp40.
      row_derive( CHANGING row = root_item ).
      root->icon           = root_item-icon.
      root->filesize_units = root_item-filesize_units.
      
      
      LOOP AT root->items REFERENCE INTO folder.
        
        CLEAR temp42.
        MOVE-CORRESPONDING folder->* TO temp42.
        
        folder_item = temp42.
        row_derive( CHANGING row = folder_item ).
        folder->icon           = folder_item-icon.
        folder->filesize_units = folder_item-filesize_units.
        
        
        LOOP AT folder->items REFERENCE INTO item.
          row_derive( CHANGING row = item->* ).
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
