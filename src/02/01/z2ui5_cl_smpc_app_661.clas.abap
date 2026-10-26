" @keywords uploadsetwithtable upload setwith table sap.m.plugins treetablewithfolderhierarchy dynamicpage treetable overflowtoolbar breadcrumbs link actionsplaceholder
" @summary This example demonstrates the usage of UploadSetwithTable plugin with a tree table featuring folder hierarchy, folder creation, folder uploads, folder navigation with breadcrumbs and folder management
" @origin sap.m.sample.UploadSetwithTablePlugin.TreeTableWithFolderHierarchy - https://sdk.openui5.org/entity/sap.m.plugins.UploadSetwithTable/sample/sap.m.sample.UploadSetwithTablePlugin.TreeTableWithFolderHierarchy (status: generated)
CLASS z2ui5_cl_smpc_app_661 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " the rows the TreeTable shows: the open folder's content, four levels deep
    TYPES:
      BEGIN OF ty_s_level4,
        documentid    TYPE string,
        filename      TYPE string,
        mimetype      TYPE string,
        imageurl      TYPE string,
        url           TYPE string,
        size          TYPE i,
        uploadeddate  TYPE string,
        uploadedby    TYPE string,
        isdirectory   TYPE abap_bool,
        status        TYPE string,
        documenttype  TYPE string,
        previewable   TYPE abap_bool,
        trustedsource TYPE abap_bool,
        color         TYPE string,
        bgcolor       TYPE string,
        uploadstate   TYPE string,
        icon          TYPE string,
        size_units    TYPE string,
      END OF ty_s_level4.
    TYPES ty_t_level4 TYPE STANDARD TABLE OF ty_s_level4 WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_level3,
        documentid    TYPE string,
        filename      TYPE string,
        mimetype      TYPE string,
        imageurl      TYPE string,
        url           TYPE string,
        size          TYPE i,
        uploadeddate  TYPE string,
        uploadedby    TYPE string,
        isdirectory   TYPE abap_bool,
        status        TYPE string,
        documenttype  TYPE string,
        previewable   TYPE abap_bool,
        trustedsource TYPE abap_bool,
        color         TYPE string,
        bgcolor       TYPE string,
        uploadstate   TYPE string,
        icon          TYPE string,
        size_units    TYPE string,
        items         TYPE ty_t_level4,
      END OF ty_s_level3.
    TYPES ty_t_level3 TYPE STANDARD TABLE OF ty_s_level3 WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_level2,
        documentid    TYPE string,
        filename      TYPE string,
        mimetype      TYPE string,
        imageurl      TYPE string,
        url           TYPE string,
        size          TYPE i,
        uploadeddate  TYPE string,
        uploadedby    TYPE string,
        isdirectory   TYPE abap_bool,
        status        TYPE string,
        documenttype  TYPE string,
        previewable   TYPE abap_bool,
        trustedsource TYPE abap_bool,
        color         TYPE string,
        bgcolor       TYPE string,
        uploadstate   TYPE string,
        icon          TYPE string,
        size_units    TYPE string,
        items         TYPE ty_t_level3,
      END OF ty_s_level2.
    TYPES ty_t_level2 TYPE STANDARD TABLE OF ty_s_level2 WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_level1,
        documentid    TYPE string,
        filename      TYPE string,
        mimetype      TYPE string,
        imageurl      TYPE string,
        url           TYPE string,
        size          TYPE i,
        uploadeddate  TYPE string,
        uploadedby    TYPE string,
        isdirectory   TYPE abap_bool,
        status        TYPE string,
        documenttype  TYPE string,
        previewable   TYPE abap_bool,
        trustedsource TYPE abap_bool,
        color         TYPE string,
        bgcolor       TYPE string,
        uploadstate   TYPE string,
        icon          TYPE string,
        size_units    TYPE string,
        items         TYPE ty_t_level2,
      END OF ty_s_level1.
    TYPES:
      BEGIN OF ty_s_history,
        name TYPE string,
        path TYPE string,
      END OF ty_s_history.
    TYPES temp1_0782f146ed TYPE STANDARD TABLE OF ty_s_level1 WITH DEFAULT KEY.
DATA t_items             TYPE temp1_0782f146ed.
    DATA currentlocationtext TYPE string.
    TYPES temp2_0782f146ed TYPE STANDARD TABLE OF ty_s_history WITH DEFAULT KEY.
DATA t_history           TYPE temp2_0782f146ed.
    " onSelectionChange's three buttons
    DATA download_enabled    TYPE abap_bool.
    DATA rename_enabled      TYPE abap_bool.
    DATA removeall_enabled   TYPE abap_bool.
    " the CreateFolderDialog fragment and the controller-built Rename Folder dialog
    DATA folder_name         TYPE string.
    DATA rename_name         TYPE string.

  PROTECTED SECTION.
    " the whole documents.json tree, flat: every node names its parent folder
    TYPES:
      BEGIN OF ty_s_doc,
        parentid      TYPE string,
        documentid    TYPE string,
        filename      TYPE string,
        mimetype      TYPE string,
        imageurl      TYPE string,
        url           TYPE string,
        size          TYPE i,
        uploadeddate  TYPE string,
        uploadedby    TYPE string,
        isdirectory   TYPE abap_bool,
        status        TYPE string,
        documenttype  TYPE string,
        previewable   TYPE abap_bool,
        trustedsource TYPE abap_bool,
        color         TYPE string,
        bgcolor       TYPE string,
        uploadstate   TYPE string,
        icon          TYPE string,
        size_units    TYPE string,
      END OF ty_s_doc.
    TYPES ty_t_index TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    TYPES temp3_0782f146ed TYPE STANDARD TABLE OF ty_s_doc WITH DEFAULT KEY.
DATA t_docs      TYPE temp3_0782f146ed.
    " the folder the table shows - initial is the root, Attachments
    DATA current_id  TYPE string.
    " the documentIds of the selected rows, of the row a removal asks about and
    " of the folder being renamed
    DATA t_selected  TYPE string_table.
    DATA remove_id   TYPE string.
    DATA rename_id   TYPE string.
    DATA new_no      TYPE i.

    METHODS view_display.
    METHODS popup_folder_display.
    METHODS popup_rename_display.
    METHODS on_event.
    METHODS selection_set
      IMPORTING
        paths TYPE string.
    METHODS download.
    METHODS folder_create
      IMPORTING
        name TYPE string.
    METHODS folder_open
      IMPORTING
        id TYPE string.
    METHODS remove_all_ask.
    METHODS remove_selected.
    METHODS rows_build.
    METHODS children_count
      IMPORTING
        parent        TYPE string
      RETURNING
        VALUE(result) TYPE i.
    METHODS doc_at_path
      IMPORTING
        path          TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS doc_delete
      IMPORTING
        id TYPE string.
    METHODS doc_insert
      IMPORTING
        doc           TYPE ty_s_doc
        after_folders TYPE abap_bool.
    METHODS path_indices
      IMPORTING
        path          TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_index.
    METHODS row_derive
      CHANGING
        row TYPE ty_s_doc.
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


CLASS z2ui5_cl_smpc_app_661 IMPLEMENTATION.

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
    DATA temp5 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp6 TYPE string_table.
    DATA temp7 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `IMAGEURL` INTO TABLE temp1.
    INSERT `UPLOADSTATE` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `uploadPlugin` INTO TABLE temp2.
    INSERT `renameItem` INTO TABLE temp2.
    
    temp3 = `$controller.getView().byId('table-uploadSet').getBinding('rows')` && `.getSelectedContexts()[0].getProperty('ISDIRECTORY') ? null : ` && `$controller.getView().byId('table-uploadSet').getBinding('rows')` && `.getSelectedContexts()[0]`.
    INSERT temp3 INTO TABLE temp2.
    
    CLEAR temp4.
    INSERT `${$parameters>/item}.getFileName()` INTO TABLE temp4.
    INSERT `${$parameters>/item}.getMediaType()` INTO TABLE temp4.
    INSERT `${$parameters>/item}.getFileObject().size` INTO TABLE temp4.
    
    CLEAR temp5.
    temp5-check_prevent_default = abap_true.
    temp5-check_queue_last = abap_true.
    
    CLEAR temp6.
    INSERT `${$parameters>/item}.getBindingContext().getPath()` INTO TABLE temp6.
    INSERT `${$parameters>/item}.getFileName()` INTO TABLE temp6.
    
    CLEAR temp7.
    INSERT `uploadPlugin` INTO TABLE temp7.
    INSERT `openFilePreview` INTO TABLE temp7.
    INSERT `$event.oSource.getBindingContext()` INTO TABLE temp7.
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
                " onToggleOpenState is an empty handler - the wire is not built
                )->ele( `TreeTable`
                    )->a( n = `id`                 v = `table-uploadSet`
                    " IMAGEURL and UPLOADSTATE stay absent where the data has none, so
                    " the view's undefined checks read as in the sample
                    )->a( n = `rows`               v = client->_bind( val                = t_items
                                                                      omit_initial_paths = temp1 )
                    )->a( n = `selectionMode`      v = `MultiToggle`
                    )->a( n = `rowSelectionChange` v = client->_event( val = `SELECTION`
                                                                       arg = `$event.oSource.getBinding('rows').getSelectedContexts().join()` )

                    )->ele( `extension`
                        )->ele( n = `OverflowToolbar` ns = `m`
                            )->a( n = `style` v = `Clear`

                            )->ele( n = `Breadcrumbs` ns = `m`
                                )->a( n = `id`                  v = `breadcrumbs`
                                )->a( n = `currentLocationText` v = client->_bind( currentlocationtext )
                                )->a( n = `links`               v = client->_bind( t_history )

                                )->tag( n = `Link` ns = `m`
                                    )->a( n = `press` v = client->_event( val = `CRUMB`
                                                                          arg = `$event.oSource.getBindingContext().getPath()` )
                                    )->a( n = `text`  v = `{NAME}`

                            )->end(
                            )->tag( n = `ActionsPlaceholder` ns = `upload`
                                )->a( n = `id`             v = `uploadButton`
                                )->a( n = `placeholderFor` v = `UploadButtonPlaceholder`
                            )->tag( n = `Button` ns = `m`
                                )->a( n = `id`      v = `downloadSelectedButton`
                                )->a( n = `text`    v = `Download`
                                )->a( n = `enabled` v = client->_bind( download_enabled )
                                )->a( n = `press`   v = client->_event( `DOWNLOAD` )
                            )->tag( n = `Button` ns = `m`
                                )->a( n = `id`    v = `addFolderButton`
                                )->a( n = `text`  v = `Add Folder`
                                )->a( n = `press` v = client->_event( `ADD_FOLDER` )
                                )->a( n = `icon`  v = `sap-icon://add-folder`
                            " onRenameItem: a folder gets the controller's dialog (backend), a file
                            " the plugin's renameItem - the second handler hands it the selected
                            " context, or null for a folder, which renameItem ignores
                            )->tag( n = `Button` ns = `m`
                                )->a( n = `id`      v = `renameButton`
                                )->a( n = `text`    v = `Rename`
                                )->a( n = `enabled` v = client->_bind( rename_enabled )
                                )->a( n = `press`   v = client->_event( `RENAME` ) && `; ` &&
                                                        client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                  t_arg = temp2 )
                            )->tag( n = `Button` ns = `m`
                                )->a( n = `id`      v = `removeAllButton`
                                )->a( n = `text`    v = `Remove All`
                                )->a( n = `enabled` v = client->_bind( removeall_enabled )
                                )->a( n = `press`   v = client->_event( `REMOVE_ALL` )

                        )->end(
                    )->end(
                    )->ele( `dependents`
                        )->ele( n = `UploadSetwithTable` ns = `plugins`
                            )->a( n = `id`                 v = `uploadPlugin`
                            )->a( n = `uploadUrl`          v = `./uploadFiles`
                            )->a( n = `multiple`           v = `true`
                            )->a( n = `uploadEnabled`      v = `true`
                            " the mock server's part: the upload is vetoed and the backend
                            " files the document into the open folder
                            )->a( n = `beforeUploadStarts` v = client->_event( val    = `UPLOAD`
                                                                               t_arg  = temp4
                                                                               s_ctrl = temp5 )
                            )->a( n = `itemRenamed`        v = client->_event( val   = `RENAMED`
                                                                               t_arg = temp6 )
                            )->a( n = `actions`            v = `uploadButton`

                            " the paths name the model's upper-case ABAP fields
                            )->tag( n = `UploadItemConfiguration` ns = `upload`
                                )->a( n = `fileNamePath`        v = `FILENAME`
                                )->a( n = `mediaTypePath`       v = `MIMETYPE`
                                )->a( n = `urlPath`             v = `URL`
                                )->a( n = `fileSizePath`        v = `SIZE`
                                )->a( n = `isDirectoryPath`     v = `ISDIRECTORY`
                                )->a( n = `previewablePath`     v = `PREVIEWABLE`
                                )->a( n = `isTrustedSourcePath` v = `TRUSTEDSOURCE`

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

                                        )->tag( n = `Link` ns = `m`
                                            )->a( n = `text`    v = `{FILENAME}`
                                            )->a( n = `press`   v = client->_event( val = `OPEN_FOLDER`
                                                                                    arg = `$event.oSource.getBindingContext().getPath()` )
                                            )->a( n = `class`   v = `sapUiSmallMarginBottom`
                                            )->a( n = `visible` v = `{= ${ISDIRECTORY} === true }`
                                        )->tag( n = `Link` ns = `m`
                                            )->a( n = `text`    v = `{FILENAME}`
                                            )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                              t_arg = temp7 )
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

                            " formatFileSize runs in ABAP as well
                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text` v = `{SIZE_UNITS}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Last Modified`

                            )->ele( `template`
                                )->ele( n = `VBox` ns = `m`
                                    )->tag( n = `Text` ns = `m`
                                        )->a( n = `text` v = `{UPLOADEDBY}`
                                    )->tag( n = `Text` ns = `m`
                                        )->a( n = `class` v = `sapUiTinyMarginTop`
                                        )->a( n = `text`  v = `{UPLOADEDDATE}`

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
                                    )->a( n = `visible` v = `{= ${ISDIRECTORY} === false }`
                                    )->a( n = `tooltip` v = `Delete File` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD popup_folder_display.

    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Dialog`
            )->a( n = `title` v = `Create New Folder`
            )->a( n = `class` v = `sapUiMediumMargin`

            )->ele( `content`
                )->ele( `VBox`
                    )->a( n = `class` v = `sapUiMediumMargin`

                    )->tag( `Label`
                        )->a( n = `text` v = `Folder name:`
                    )->tag( `Input`
                        )->a( n = `id`          v = `folderNameInput`
                        )->a( n = `value`       v = client->_bind( folder_name )
                        )->a( n = `placeholder` v = `Enter folder name`

                )->end(
            )->end(
            )->ele( `buttons`
                )->tag( `Button`
                    )->a( n = `text`  v = `Create`
                    )->a( n = `type`  v = `Emphasized`
                    )->a( n = `press` v = client->_event( `CREATE_FOLDER` )
                )->tag( `Button`
                    )->a( n = `text`  v = `Cancel`
                    )->a( n = `press` v = client->follow_up_action( client->cs_event-popup_close ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD popup_rename_display.

    " renameFolderWithDialog builds this Dialog in the controller
    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Dialog`
            )->a( n = `title` v = `Rename Folder`

            )->ele( `content`
                )->tag( `Input`
                    )->a( n = `value` v = client->_bind( rename_name )
                    )->a( n = `width` v = `100%`

            )->end(
            )->ele( `beginButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `OK`
                    )->a( n = `type`  v = `Emphasized`
                    )->a( n = `press` v = client->_event( `RENAME_FOLDER_OK` )

            )->end(
            )->ele( `endButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `Cancel`
                    )->a( n = `press` v = client->follow_up_action( client->cs_event-popup_close ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA name TYPE string.
        DATA selected LIKE LINE OF t_docs.
        FIELD-SYMBOLS <temp5> LIKE LINE OF t_docs.
        DATA temp6 LIKE sy-tabix.
        FIELD-SYMBOLS <temp8> LIKE LINE OF t_selected.
        DATA temp10 LIKE sy-tabix.
        FIELD-SYMBOLS <temp3> TYPE z2ui5_cl_smpc_app_661=>ty_s_doc.
DATA folder LIKE REF TO <temp3>.
        DATA new_name TYPE string.
        DATA renamed TYPE string.
          FIELD-SYMBOLS <temp4> LIKE LINE OF t_docs.
          DATA temp5 LIKE sy-tabix.
        DATA crumb TYPE z2ui5_cl_smpc_app_661=>ty_t_index.
        FIELD-SYMBOLS <temp6> LIKE LINE OF crumb.
        DATA temp7 LIKE sy-tabix.
        DATA entry LIKE LINE OF t_history.
        FIELD-SYMBOLS <temp7> LIKE LINE OF t_history.
        DATA temp9 LIKE sy-tabix.
        FIELD-SYMBOLS <temp11> LIKE LINE OF crumb.
        DATA temp12 LIKE sy-tabix.
        DATA doc LIKE LINE OF t_docs.
        FIELD-SYMBOLS <temp10> LIKE LINE OF t_docs.
        DATA temp11 LIKE sy-tabix.
          DATA removed TYPE z2ui5_cl_smpc_app_661=>ty_s_doc-filename.
          FIELD-SYMBOLS <temp12> LIKE LINE OF t_docs.
          DATA temp13 LIKE sy-tabix.
        DATA temp8 TYPE ty_s_doc.
        DATA temp14 TYPE z2ui5_cl_smpc_app_661=>ty_s_doc-size.
        DATA file LIKE temp8.

    CASE client->get_event( ).

      WHEN `SELECTION`.
        selection_set( client->get_event_arg( ) ).

      WHEN `DOWNLOAD`.
        download( ).

      WHEN `ADD_FOLDER`.
        " onCreateFolder - the dialog opens with an empty name
        folder_name = ``.
        popup_folder_display( ).

      WHEN `CREATE_FOLDER`.
        " onCreateFolderDialogPress - an empty name keeps the dialog open
        
        name = condense( folder_name ).
        IF name IS INITIAL.
          client->message_toast_display( `Please enter a folder name` ).
          RETURN.
        ENDIF.
        client->popup_destroy( ).
        folder_create( name ).

      WHEN `RENAME`.
        " onRenameItem - the plugin renames a file (the press's second handler);
        " a folder is renamed in the controller's own dialog
        IF lines( t_selected ) <> 1.
          client->message_toast_display( `Please select exactly one item to rename` ).
          RETURN.
        ENDIF.
        
        
        
        temp6 = sy-tabix.
        
        
        temp10 = sy-tabix.
        READ TABLE t_selected INDEX 1 ASSIGNING <temp8>.
        sy-tabix = temp10.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        READ TABLE t_docs WITH KEY documentid = <temp8> ASSIGNING <temp5>.
        sy-tabix = temp6.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        selected = <temp5>.
        IF selected-isdirectory = abap_true.
          rename_id   = selected-documentid.
          rename_name = selected-filename.
          popup_rename_display( ).
        ENDIF.

      WHEN `RENAME_FOLDER_OK`.
        
        READ TABLE t_docs WITH KEY documentid = rename_id ASSIGNING <temp3>.
IF sy-subrc <> 0.
  ASSERT 1 = 0.
ENDIF.

GET REFERENCE OF <temp3> INTO folder.
        
        new_name = condense( rename_name ).
        IF new_name IS NOT INITIAL AND new_name <> folder->filename.
          folder->filename = new_name.
          rows_build( ).
          client->message_toast_display( `Folder renamed successfully` ).
        ENDIF.
        client->popup_destroy( ).

      WHEN `RENAMED`.
        " onDocumentRenamedSuccess
        
        renamed = doc_at_path( client->get_event_arg( ) ).
        IF renamed IS NOT INITIAL.
          
          
          temp5 = sy-tabix.
          READ TABLE t_docs WITH KEY documentid = renamed ASSIGNING <temp4>.
          sy-tabix = temp5.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp4>-filename = client->get_event_arg( 2 ).
          rows_build( ).
          client->message_toast_display( text = `File renamed successfully` duration = `2000` ).
        ENDIF.

      WHEN `OPEN_FOLDER`.
        " onItemPress - navigateToFolder
        folder_open( doc_at_path( client->get_event_arg( ) ) ).

      WHEN `CRUMB`.
        " onBreadcrumbPress - a link is one level of the history
        
        crumb = path_indices( client->get_event_arg( ) ).
        
        
        temp7 = sy-tabix.
        READ TABLE crumb INDEX 1 ASSIGNING <temp6>.
        sy-tabix = temp7.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        IF crumb IS INITIAL OR <temp6> > lines( t_history ).
          RETURN.
        ENDIF.
        
        
        
        temp9 = sy-tabix.
        
        
        temp12 = sy-tabix.
        READ TABLE crumb INDEX 1 ASSIGNING <temp11>.
        sy-tabix = temp12.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        READ TABLE t_history INDEX <temp11> ASSIGNING <temp7>.
        sy-tabix = temp9.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        entry = <temp7>.
        folder_open( entry-path ).

      WHEN `REMOVE_ROW`.
        " onRemoveItemHandler - files only, the button is hidden on folders
        
        
        
        temp11 = sy-tabix.
        READ TABLE t_docs WITH KEY documentid = doc_at_path( client->get_event_arg( ) ) ASSIGNING <temp10>.
        sy-tabix = temp11.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        doc = <temp10>.
        IF doc-isdirectory = abap_true.
          client->message_toast_display( `Folder deletion is not allowed` ).
          RETURN.
        ENDIF.
        remove_id = doc-documentid.
        client->message_box_display( text    = |Are you sure you want to delete the file '{ doc-filename }'?|
                                     type    = `confirm`
                                     title   = `Delete File`
                                     onclose = `REMOVE_CLOSE` ).

      WHEN `REMOVE_CLOSE`.
        " the file is filtered out of the OPEN folder's items
        IF client->get_event_arg( ) = `OK`.
          
          
          
          temp13 = sy-tabix.
          READ TABLE t_docs WITH KEY documentid = remove_id ASSIGNING <temp12>.
          sy-tabix = temp13.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          removed = <temp12>-filename.
          DELETE t_docs WHERE documentid = remove_id AND parentid = current_id.
          rows_build( ).
          client->message_toast_display( |File '{ removed }' deleted successfully| ).
        ENDIF.

      WHEN `REMOVE_ALL`.
        remove_all_ask( ).

      WHEN `REMOVE_ALL_CLOSE`.
        IF client->get_event_arg( ) = `OK`.
          remove_selected( ).
        ENDIF.

      WHEN `UPLOAD`.
        " the mock server files the upload into the open folder, after its folders
        new_no = new_no + 1.
        
        CLEAR temp8.
        temp8-parentid = current_id.
        temp8-documentid = |upload-{ new_no }|.
        temp8-filename = client->get_event_arg( ).
        temp8-mimetype = client->get_event_arg( 2 ).
        
        temp14 = client->get_event_arg( 3 ).
        temp8-size = temp14.
        temp8-uploadeddate = |{ sy-datum DATE = ISO }|.
        temp8-uploadedby = `Current User`.
        temp8-uploadstate = `Complete`.
        temp8-trustedsource = abap_true.
        
        file = temp8.
        row_derive( CHANGING row = file ).
        doc_insert( doc = file after_folders = abap_true ).
        rows_build( ).
        client->message_toast_display( `Upload completed successfully.` ).

    ENDCASE.

  ENDMETHOD.


  METHOD selection_set.

    " onSelectionChange - files and folders are told apart, and Remove All needs
    " every item of the open folder selected
    DATA temp9 TYPE string_table.
      TYPES temp4 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA selected_paths TYPE temp4.
      DATA path LIKE LINE OF selected_paths.
        DATA id TYPE string.
    DATA files TYPE i.
    DATA folders TYPE i.
      FIELD-SYMBOLS <temp10> LIKE LINE OF t_docs.
      DATA temp11 LIKE sy-tabix.
    DATA total TYPE i.
    DATA temp1 TYPE xsdboolean.
      DATA temp2 TYPE xsdboolean.
      DATA temp3 TYPE xsdboolean.
    CLEAR temp9.
    t_selected = temp9.
    IF paths IS NOT INITIAL.
      

      SPLIT paths AT `,` INTO TABLE selected_paths.
      
      LOOP AT selected_paths INTO path.
        
        id = doc_at_path( path ).
        IF id IS NOT INITIAL.
          INSERT id INTO TABLE t_selected.
        ENDIF.
      ENDLOOP.
    ENDIF.
    
    files = 0.
    
    folders = 0.
    LOOP AT t_selected INTO id.
      
      
      temp11 = sy-tabix.
      READ TABLE t_docs WITH KEY documentid = id ASSIGNING <temp10>.
      sy-tabix = temp11.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      IF <temp10>-isdirectory = abap_true.
        folders = folders + 1.
      ELSE.
        files = files + 1.
      ENDIF.
    ENDLOOP.
    
    total = children_count( current_id ).
    
    temp1 = boolc( t_selected IS NOT INITIAL AND lines( t_selected ) = total AND total > 0 ).
    removeall_enabled = temp1.
    IF files > 0 AND folders = 0.
      download_enabled = abap_true.
      
      temp2 = boolc( files = 1 ).
      rename_enabled   = temp2.
    ELSEIF folders > 0 AND files = 0.
      download_enabled = abap_false.
      
      temp3 = boolc( folders = 1 ).
      rename_enabled   = temp3.
    ELSE.
      download_enabled = abap_false.
      rename_enabled   = abap_false.
    ENDIF.

  ENDMETHOD.


  METHOD download.

    " onDownloadFiles - one <a download> click per selected file with a URL
    DATA files TYPE i.
    DATA id LIKE LINE OF t_selected.
      DATA doc LIKE LINE OF t_docs.
      FIELD-SYMBOLS <temp15> LIKE LINE OF t_docs.
      DATA temp16 LIKE sy-tabix.
        DATA temp12 TYPE string_table.
    files = 0.
    
    LOOP AT t_selected INTO id.
      
      
      
      temp16 = sy-tabix.
      READ TABLE t_docs WITH KEY documentid = id ASSIGNING <temp15>.
      sy-tabix = temp16.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      doc = <temp15>.
      IF doc-isdirectory = abap_true.
        CONTINUE.
      ENDIF.
      files = files + 1.
      IF doc-url IS NOT INITIAL.
        
        CLEAR temp12.
        INSERT doc-url INTO TABLE temp12.
        INSERT doc-filename INTO TABLE temp12.
        client->follow_up_action( val   = client->cs_event-download_b64_file
                                  t_arg = temp12 ).
      ENDIF.
    ENDLOOP.
    IF files = 0.
      client->message_toast_display( `No files selected for download` ).
      RETURN.
    ENDIF.
    client->message_toast_display( |Download initiated for { files } file(s)| ).

  ENDMETHOD.


  METHOD folder_create.

    " createFolderWithName - into the one selected folder, else the open one
    DATA target LIKE current_id.
    DATA inside TYPE string.
    DATA selected_folders TYPE i.
    DATA id LIKE LINE OF t_selected.
      FIELD-SYMBOLS <temp14> LIKE LINE OF t_docs.
      DATA temp15 LIKE sy-tabix.
      FIELD-SYMBOLS <temp16> LIKE LINE OF t_docs.
      DATA temp17 LIKE sy-tabix.
    DATA temp18 LIKE sy-subrc.
    DATA temp19 TYPE ty_s_doc.
    DATA folder LIKE temp19.
    target = current_id.
    
    inside = ``.
    
    selected_folders = 0.
    
    LOOP AT t_selected INTO id.
      
      
      temp15 = sy-tabix.
      READ TABLE t_docs WITH KEY documentid = id ASSIGNING <temp14>.
      sy-tabix = temp15.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      IF <temp14>-isdirectory = abap_true.
        selected_folders = selected_folders + 1.
        target = id.
      ENDIF.
    ENDLOOP.
    IF selected_folders = 1.
      
      
      temp17 = sy-tabix.
      READ TABLE t_docs WITH KEY documentid = target ASSIGNING <temp16>.
      sy-tabix = temp17.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      inside = <temp16>-filename.
    ELSE.
      target = current_id.
    ENDIF.
    
    READ TABLE t_docs WITH KEY parentid = target filename = name TRANSPORTING NO FIELDS.
    temp18 = sy-subrc.
    IF temp18 = 0.
      client->message_toast_display( `A folder with this name already exists` ).
      RETURN.
    ENDIF.
    new_no = new_no + 1.
    
    CLEAR temp19.
    temp19-parentid = target.
    temp19-documentid = |folder-new-{ new_no }|.
    temp19-filename = name.
    temp19-isdirectory = abap_true.
    temp19-uploadeddate = |{ sy-datum DATE = ISO }|.
    temp19-uploadedby = `Current User`.
    temp19-status = `Active`.
    temp19-documenttype = `Folder`.
    temp19-color = `#ffffff`.
    temp19-bgcolor = `#30914c`.
    temp19-uploadstate = `Complete`.
    
    folder = temp19.
    row_derive( CHANGING row = folder ).
    doc_insert( doc = folder after_folders = abap_false ).
    rows_build( ).
    IF selected_folders = 1.
      client->message_toast_display( |New folder created inside '{ inside }': { name }| ).
    ELSE.
      client->message_toast_display( |New folder created: { name }| ).
    ENDIF.

  ENDMETHOD.


  METHOD folder_open.
    DATA temp20 LIKE t_history.
      FIELD-SYMBOLS <temp21> LIKE LINE OF t_docs.
      DATA temp22 LIKE sy-tabix.
      DATA parent TYPE z2ui5_cl_smpc_app_661=>ty_s_doc-parentid.
      FIELD-SYMBOLS <temp17> LIKE LINE OF t_docs.
      DATA temp18 LIKE sy-tabix.
        DATA temp23 TYPE z2ui5_cl_smpc_app_661=>ty_s_history.
        FIELD-SYMBOLS <temp19> LIKE LINE OF t_docs.
        DATA temp21 LIKE sy-tabix.
        FIELD-SYMBOLS <temp24> LIKE LINE OF t_docs.
        DATA temp25 LIKE sy-tabix.
      DATA temp26 TYPE z2ui5_cl_smpc_app_661=>ty_s_history.
    DATA temp27 TYPE string_table.
    DATA temp28 TYPE string_table.

    " bindTableItems on the folder's items, the Breadcrumbs history up to its
    " parent and the folder as the current location; initial is the root
    current_id = id.
    
    CLEAR temp20.
    t_history  = temp20.
    IF id IS INITIAL.
      currentlocationtext = `Attachments`.
    ELSE.
      
      
      temp22 = sy-tabix.
      READ TABLE t_docs WITH KEY documentid = id ASSIGNING <temp21>.
      sy-tabix = temp22.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      currentlocationtext = <temp21>-filename.
      
      
      
      temp18 = sy-tabix.
      READ TABLE t_docs WITH KEY documentid = id ASSIGNING <temp17>.
      sy-tabix = temp18.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      parent = <temp17>-parentid.
      WHILE parent IS NOT INITIAL.
        
        CLEAR temp23.
        
        
        temp21 = sy-tabix.
        READ TABLE t_docs WITH KEY documentid = parent ASSIGNING <temp19>.
        sy-tabix = temp21.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        temp23-name = <temp19>-filename.
        temp23-path = parent.
        INSERT temp23 INTO t_history INDEX 1.
        
        
        temp25 = sy-tabix.
        READ TABLE t_docs WITH KEY documentid = parent ASSIGNING <temp24>.
        sy-tabix = temp25.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        parent = <temp24>-parentid.
      ENDWHILE.
      
      CLEAR temp26.
      temp26-name = `Attachments`.
      INSERT temp26 INTO t_history INDEX 1.
    ENDIF.
    rows_build( ).
    " the rebound rows start without a selection
    
    CLEAR temp27.
    t_selected        = temp27.
    download_enabled  = abap_false.
    rename_enabled    = abap_false.
    removeall_enabled = abap_false.
    
    CLEAR temp28.
    INSERT `table-uploadSet` INTO TABLE temp28.
    INSERT `clearSelection` INTO TABLE temp28.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp28 ).

  ENDMETHOD.


  METHOD remove_all_ask.

    " onRemoveAllHandler - only when every item of the open folder is selected
    IF t_selected IS INITIAL.
      client->message_toast_display( `Please select items to delete` ).
      RETURN.
    ENDIF.
    IF lines( t_selected ) <> children_count( current_id ).
      client->message_toast_display( `Please select all items to use Remove All` ).
      RETURN.
    ENDIF.
    client->message_box_display( text    = |Are you sure you want to delete ALL { lines( t_selected ) } item(s) in this folder?|
                                 type    = `confirm`
                                 title   = `Delete All Items`
                                 onclose = `REMOVE_ALL_CLOSE` ).

  ENDMETHOD.


  METHOD remove_selected.

    " deleteAllSelectedItems - files and folders of the open folder
    DATA deleted TYPE i.
    DATA id LIKE LINE OF t_selected.
      DATA temp30 LIKE sy-subrc.
    DATA temp31 TYPE string_table.
    deleted = 0.
    
    LOOP AT t_selected INTO id.
      
      READ TABLE t_docs WITH KEY documentid = id parentid = current_id TRANSPORTING NO FIELDS.
      temp30 = sy-subrc.
      IF temp30 = 0.
        doc_delete( id ).
        deleted = deleted + 1.
      ENDIF.
    ENDLOOP.
    IF deleted = 0.
      client->message_toast_display( `No items were found to delete` ).
      RETURN.
    ENDIF.
    
    CLEAR temp31.
    t_selected = temp31.
    rows_build( ).
    client->message_toast_display( |{ deleted } item(s) deleted successfully| ).

  ENDMETHOD.


  METHOD rows_build.

    " the open folder's subtree as the TreeTable's rows
    DATA temp32 LIKE t_items.
    DATA doc1 LIKE LINE OF t_docs.
      DATA temp33 TYPE ty_s_level1.
      DATA level1 LIKE temp33.
      DATA doc2 LIKE LINE OF t_docs.
        DATA temp34 TYPE ty_s_level2.
        DATA level2 LIKE temp34.
        DATA doc3 LIKE LINE OF t_docs.
          DATA temp35 TYPE ty_s_level3.
          DATA level3 LIKE temp35.
          DATA doc4 LIKE LINE OF t_docs.
            DATA temp36 TYPE ty_s_level4.
    CLEAR temp32.
    t_items = temp32.
    
    LOOP AT t_docs INTO doc1 WHERE parentid = current_id.
      
      CLEAR temp33.
      MOVE-CORRESPONDING doc1 TO temp33.
      
      level1 = temp33.
      
      LOOP AT t_docs INTO doc2 WHERE parentid = doc1-documentid.
        
        CLEAR temp34.
        MOVE-CORRESPONDING doc2 TO temp34.
        
        level2 = temp34.
        
        LOOP AT t_docs INTO doc3 WHERE parentid = doc2-documentid.
          
          CLEAR temp35.
          MOVE-CORRESPONDING doc3 TO temp35.
          
          level3 = temp35.
          
          LOOP AT t_docs INTO doc4 WHERE parentid = doc3-documentid.
            
            CLEAR temp36.
            MOVE-CORRESPONDING doc4 TO temp36.
            INSERT temp36 INTO TABLE level3-items.
          ENDLOOP.
          INSERT level3 INTO TABLE level2-items.
        ENDLOOP.
        INSERT level2 INTO TABLE level1-items.
      ENDLOOP.
      INSERT level1 INTO TABLE t_items.
    ENDLOOP.

  ENDMETHOD.


  METHOD children_count.

    LOOP AT t_docs TRANSPORTING NO FIELDS WHERE parentid = parent.
      result = result + 1.
    ENDLOOP.

  ENDMETHOD.


  METHOD doc_at_path.

    " a row's binding path holds its position on every level below the open
    " folder: /T_ITEMS/0/ITEMS/1 is the 2nd child of its 1st item
    DATA parent LIKE current_id.
    DATA levels TYPE z2ui5_cl_smpc_app_661=>ty_t_index.
    DATA index LIKE LINE OF levels.
      DATA position TYPE i.
      DATA doc LIKE LINE OF t_docs.
    parent = current_id.
    
    levels = path_indices( path ).
    
    LOOP AT levels INTO index.
      result = ``.
      
      position = 0.
      
      LOOP AT t_docs INTO doc WHERE parentid = parent.
        position = position + 1.
        IF position = index.
          result = doc-documentid.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF result IS INITIAL.
        RETURN.
      ENDIF.
      parent = result.
    ENDLOOP.

  ENDMETHOD.


  METHOD doc_delete.

    " the node and, below a folder, everything in it
    DATA child LIKE LINE OF t_docs.
    LOOP AT t_docs INTO child WHERE parentid = id.
      doc_delete( child-documentid ).
    ENDLOOP.
    DELETE t_docs WHERE documentid = id.

  ENDMETHOD.


  METHOD doc_insert.

    " unshift into the parent's items - or, for an uploaded file, in front of
    " its first file (behind the folders)
    DATA sibling LIKE LINE OF t_docs.
    LOOP AT t_docs INTO sibling WHERE parentid = doc-parentid.
      IF after_folders = abap_false OR sibling-isdirectory = abap_false.
        INSERT doc INTO t_docs INDEX sy-tabix.
        RETURN.
      ENDIF.
    ENDLOOP.
    INSERT doc INTO TABLE t_docs.

  ENDMETHOD.


  METHOD path_indices.

    TYPES temp5 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA parts TYPE temp5.
    DATA part LIKE LINE OF parts.
        DATA temp37 LIKE LINE OF result.
        DATA temp22 LIKE LINE OF result.
    SPLIT path AT `/` INTO TABLE parts.
    
    LOOP AT parts INTO part.
      IF part IS NOT INITIAL AND part CO `0123456789`.
        
        temp37 = part.
        
        temp22 = temp37 + 1.
        INSERT temp22 INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD row_derive.

    " getIconSrc - a folder icon for a directory - and formatFileSize
    IF row-isdirectory = abap_true.
      row-icon = `sap-icon://folder-full`.
    ELSE.
      row-icon = icon_for( mediatype = row-mimetype filename = row-filename ).
    ENDIF.
    row-size_units = size_with_units( row-size ).

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
    DATA temp38 TYPE decfloat34.
    DATA bytes LIKE temp38.
    temp38 = size.
    
    bytes = temp38.
    IF size < kilobyte * kilobyte.
      result = |{ bytes / kilobyte DECIMALS = 2 } KB|.
    ELSEIF size < kilobyte * kilobyte * kilobyte.
      result = |{ bytes / kilobyte / kilobyte DECIMALS = 2 } MB|.
    ELSE.
      result = |{ bytes / kilobyte / kilobyte / kilobyte DECIMALS = 2 } GB|.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " model/documents.json, the whole tree flattened - the document URLs point at
    " the OpenUI5 host
    DATA temp39 LIKE t_docs.
    DATA temp40 LIKE LINE OF temp39.
    DATA temp41 LIKE LINE OF t_docs.
    DATA doc LIKE REF TO temp41.
    CLEAR temp39.
    
    CLEAR temp40.
    temp40-documentid = `folder-1`.
    temp40-filename = `My Documents`.
    temp40-isdirectory = abap_true.
    temp40-size = 0.
    temp40-uploadeddate = `2023-01-15`.
    temp40-uploadedby = `System`.
    temp40-status = `Active`.
    temp40-documenttype = `Folder`.
    temp40-color = `#ffffff`.
    temp40-bgcolor = `#30914c`.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-parentid = `folder-1`.
    temp40-documentid = `folder-images`.
    temp40-filename = `Images`.
    temp40-isdirectory = abap_true.
    temp40-size = 0.
    temp40-uploadeddate = `2023-02-10`.
    temp40-uploadedby = `User`.
    temp40-status = `Active`.
    temp40-documenttype = `Folder`.
    temp40-color = `#ffffff`.
    temp40-bgcolor = `#30914c`.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-parentid = `folder-images`.
    temp40-documentid = `img-001`.
    temp40-filename = `Animation.gif`.
    temp40-mimetype = `image/gif`.
    temp40-isdirectory = abap_false.
    temp40-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`.
    temp40-size = 1048576.
    temp40-uploadeddate = `2023-03-05`.
    temp40-uploadedby = `John Doe`.
    temp40-status = `Complete`.
    temp40-documenttype = `Image`.
    temp40-previewable = abap_true.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-parentid = `folder-images`.
    temp40-documentid = `folder-screenshots`.
    temp40-filename = `Screenshots`.
    temp40-isdirectory = abap_true.
    temp40-size = 0.
    temp40-uploadeddate = `2023-04-01`.
    temp40-uploadedby = `User`.
    temp40-status = `Active`.
    temp40-documenttype = `Folder`.
    temp40-color = `#ffffff`.
    temp40-bgcolor = `#30914c`.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-parentid = `folder-screenshots`.
    temp40-documentid = `screenshot-001`.
    temp40-filename = `Video.mp4`.
    temp40-mimetype = `video/mp4`.
    temp40-isdirectory = abap_false.
    temp40-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Video.mp4`.
    temp40-size = 42000000.
    temp40-uploadeddate = `2023-04-01`.
    temp40-uploadedby = `Current User`.
    temp40-status = `Complete`.
    temp40-documenttype = `Video`.
    temp40-previewable = abap_true.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-parentid = `folder-1`.
    temp40-documentid = `folder-reports`.
    temp40-filename = `Reports`.
    temp40-isdirectory = abap_true.
    temp40-size = 0.
    temp40-uploadeddate = `2023-02-15`.
    temp40-uploadedby = `Admin`.
    temp40-status = `Active`.
    temp40-documenttype = `Folder`.
    temp40-color = `#ffffff`.
    temp40-bgcolor = `#30914c`.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-parentid = `folder-reports`.
    temp40-documentid = `report-001`.
    temp40-filename = `Instructions.pdf`.
    temp40-mimetype = `application/pdf`.
    temp40-isdirectory = abap_false.
    temp40-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Instructions.pdf`.
    temp40-size = 30000.
    temp40-uploadeddate = `2023-04-01`.
    temp40-uploadedby = `Finance Team`.
    temp40-status = `Complete`.
    temp40-documenttype = `Document`.
    temp40-previewable = abap_true.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-parentid = `folder-reports`.
    temp40-documentid = `report-002`.
    temp40-filename = `Business Plan Agenda.doc`.
    temp40-mimetype = `application/msword`.
    temp40-isdirectory = abap_false.
    temp40-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Agenda.doc`.
    temp40-size = 200000.
    temp40-uploadeddate = `2023-04-02`.
    temp40-uploadedby = `Planning Team`.
    temp40-status = `Complete`.
    temp40-documenttype = `Document`.
    temp40-previewable = abap_true.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-parentid = `folder-1`.
    temp40-documentid = `doc-002`.
    temp40-filename = `Third Quarter Results.ppt`.
    temp40-mimetype = `application/vnd.ms-powerpoint`.
    temp40-isdirectory = abap_false.
    temp40-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Third Quarter Results.ppt`.
    temp40-size = 3145728.
    temp40-uploadeddate = `2023-03-15`.
    temp40-uploadedby = `Support Team`.
    temp40-status = `Complete`.
    temp40-documenttype = `Presentation`.
    temp40-previewable = abap_true.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-documentid = `doc-001`.
    temp40-filename = `Document.txt`.
    temp40-mimetype = `text/plain`.
    temp40-isdirectory = abap_false.
    temp40-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Document.txt`.
    temp40-size = 420.
    temp40-uploadeddate = `2023-02-20`.
    temp40-uploadedby = `User`.
    temp40-status = `Complete`.
    temp40-documenttype = `Document`.
    temp40-previewable = abap_true.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-documentid = `doc-003`.
    temp40-filename = `Business Plan Topics.xls`.
    temp40-mimetype = `application/vnd.ms-excel`.
    temp40-isdirectory = abap_false.
    temp40-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Topics.xls`.
    temp40-size = 1048576.
    temp40-uploadeddate = `2023-03-20`.
    temp40-uploadedby = `Marketing`.
    temp40-status = `In work`.
    temp40-documenttype = `Spreadsheet`.
    temp40-previewable = abap_true.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-documentid = `doc-004`.
    temp40-filename = `sample-zip-file.zip`.
    temp40-mimetype = `application/zip`.
    temp40-isdirectory = abap_false.
    temp40-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/sample-zip-file.zip`.
    temp40-size = 42000.
    temp40-uploadeddate = `2023-03-25`.
    temp40-uploadedby = `Development Team`.
    temp40-status = `Complete`.
    temp40-documenttype = `Archive`.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-documentid = `folder-temp`.
    temp40-filename = `Temporary Files`.
    temp40-isdirectory = abap_true.
    temp40-size = 0.
    temp40-uploadeddate = `2023-04-01`.
    temp40-uploadedby = `System`.
    temp40-status = `Active`.
    temp40-documenttype = `Folder`.
    temp40-color = `#ffffff`.
    temp40-bgcolor = `#30914c`.
    INSERT temp40 INTO TABLE temp39.
    CLEAR temp40.
    temp40-parentid = `folder-temp`.
    temp40-documentid = `temp-001`.
    temp40-filename = `Notes.txt`.
    temp40-mimetype = `text/plain`.
    temp40-isdirectory = abap_false.
    temp40-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Notes.txt`.
    temp40-size = 2048.
    temp40-uploadeddate = `2023-04-01`.
    temp40-uploadedby = `System`.
    temp40-status = `Complete`.
    temp40-documenttype = `Document`.
    temp40-previewable = abap_true.
    INSERT temp40 INTO TABLE temp39.
    t_docs = temp39.
    
    
    LOOP AT t_docs REFERENCE INTO doc.
      row_derive( CHANGING row = doc->* ).
    ENDLOOP.
    folder_open( `` ).

  ENDMETHOD.

ENDCLASS.
