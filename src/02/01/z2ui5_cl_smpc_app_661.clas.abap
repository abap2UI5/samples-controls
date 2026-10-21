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
    TYPES ty_t_level4 TYPE STANDARD TABLE OF ty_s_level4 WITH EMPTY KEY.
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
    TYPES ty_t_level3 TYPE STANDARD TABLE OF ty_s_level3 WITH EMPTY KEY.
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
    TYPES ty_t_level2 TYPE STANDARD TABLE OF ty_s_level2 WITH EMPTY KEY.
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
    DATA t_items             TYPE STANDARD TABLE OF ty_s_level1 WITH EMPTY KEY.
    DATA currentlocationtext TYPE string.
    DATA t_history           TYPE STANDARD TABLE OF ty_s_history WITH EMPTY KEY.
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
    TYPES ty_t_index TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    DATA t_docs      TYPE STANDARD TABLE OF ty_s_doc WITH EMPTY KEY.
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
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

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
                                                                      omit_initial_paths = VALUE #( ( `IMAGEURL` )
                                                                                                    ( `UPLOADSTATE` ) ) )
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
                                                                                  t_arg = VALUE #( ( `uploadPlugin` )
                                                                                                   ( `renameItem` )
                                                                                                   ( `$controller.getView().byId('table-uploadSet').getBinding('rows')` &&
                                                                                                     `.getSelectedContexts()[0].getProperty('ISDIRECTORY') ? null : ` &&
                                                                                                     `$controller.getView().byId('table-uploadSet').getBinding('rows')` &&
                                                                                                     `.getSelectedContexts()[0]` ) ) )
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
                                                                               t_arg  = VALUE #( ( `${$parameters>/item}.getFileName()` )
                                                                                                 ( `${$parameters>/item}.getMediaType()` )
                                                                                                 ( `${$parameters>/item}.getFileObject().size` ) )
                                                                               s_ctrl = VALUE #( check_prevent_default = abap_true
                                                                                                 check_queue_last      = abap_true ) )
                            )->a( n = `itemRenamed`        v = client->_event( val   = `RENAMED`
                                                                               t_arg = VALUE #( ( `${$parameters>/item}.getBindingContext().getPath()` )
                                                                                                ( `${$parameters>/item}.getFileName()` ) ) )
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
                                                                                              t_arg = VALUE #( ( `uploadPlugin` )
                                                                                                               ( `openFilePreview` )
                                                                                                               ( `$event.oSource.getBindingContext()` ) ) )
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

    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

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
    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

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
        DATA(name) = condense( folder_name ).
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
        DATA(selected) = t_docs[ documentid = t_selected[ 1 ] ].
        IF selected-isdirectory = abap_true.
          rename_id   = selected-documentid.
          rename_name = selected-filename.
          popup_rename_display( ).
        ENDIF.

      WHEN `RENAME_FOLDER_OK`.
        DATA(folder) = REF #( t_docs[ documentid = rename_id ] ).
        DATA(new_name) = condense( rename_name ).
        IF new_name IS NOT INITIAL AND new_name <> folder->filename.
          folder->filename = new_name.
          rows_build( ).
          client->message_toast_display( `Folder renamed successfully` ).
        ENDIF.
        client->popup_destroy( ).

      WHEN `RENAMED`.
        " onDocumentRenamedSuccess
        DATA(renamed) = doc_at_path( client->get_event_arg( ) ).
        IF renamed IS NOT INITIAL.
          t_docs[ documentid = renamed ]-filename = client->get_event_arg( 2 ).
          rows_build( ).
          client->message_toast_display( text = `File renamed successfully` duration = `2000` ).
        ENDIF.

      WHEN `OPEN_FOLDER`.
        " onItemPress - navigateToFolder
        folder_open( doc_at_path( client->get_event_arg( ) ) ).

      WHEN `CRUMB`.
        " onBreadcrumbPress - a link is one level of the history
        DATA(crumb) = path_indices( client->get_event_arg( ) ).
        IF crumb IS INITIAL OR crumb[ 1 ] > lines( t_history ).
          RETURN.
        ENDIF.
        DATA(entry) = t_history[ crumb[ 1 ] ].
        folder_open( entry-path ).

      WHEN `REMOVE_ROW`.
        " onRemoveItemHandler - files only, the button is hidden on folders
        DATA(doc) = t_docs[ documentid = doc_at_path( client->get_event_arg( ) ) ].
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
          DATA(removed) = t_docs[ documentid = remove_id ]-filename.
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
        DATA(file) = VALUE ty_s_doc( parentid      = current_id
                                     documentid    = |upload-{ new_no }|
                                     filename      = client->get_event_arg( )
                                     mimetype      = client->get_event_arg( 2 )
                                     size          = CONV #( client->get_event_arg( 3 ) )
                                     uploadeddate  = |{ sy-datum DATE = ISO }|
                                     uploadedby    = `Current User`
                                     uploadstate   = `Complete`
                                     trustedsource = abap_true ).
        row_derive( CHANGING row = file ).
        doc_insert( doc = file after_folders = abap_true ).
        rows_build( ).
        client->message_toast_display( `Upload completed successfully.` ).

    ENDCASE.

  ENDMETHOD.


  METHOD selection_set.

    " onSelectionChange - files and folders are told apart, and Remove All needs
    " every item of the open folder selected
    t_selected = VALUE #( ).
    IF paths IS NOT INITIAL.
      SPLIT paths AT `,` INTO TABLE DATA(selected_paths).
      LOOP AT selected_paths INTO DATA(path).
        DATA(id) = doc_at_path( path ).
        IF id IS NOT INITIAL.
          INSERT id INTO TABLE t_selected.
        ENDIF.
      ENDLOOP.
    ENDIF.
    DATA(files) = 0.
    DATA(folders) = 0.
    LOOP AT t_selected INTO id.
      IF t_docs[ documentid = id ]-isdirectory = abap_true.
        folders = folders + 1.
      ELSE.
        files = files + 1.
      ENDIF.
    ENDLOOP.
    DATA(total) = children_count( current_id ).
    removeall_enabled = xsdbool( t_selected IS NOT INITIAL AND lines( t_selected ) = total AND total > 0 ).
    IF files > 0 AND folders = 0.
      download_enabled = abap_true.
      rename_enabled   = xsdbool( files = 1 ).
    ELSEIF folders > 0 AND files = 0.
      download_enabled = abap_false.
      rename_enabled   = xsdbool( folders = 1 ).
    ELSE.
      download_enabled = abap_false.
      rename_enabled   = abap_false.
    ENDIF.

  ENDMETHOD.


  METHOD download.

    " onDownloadFiles - one <a download> click per selected file with a URL
    DATA(files) = 0.
    LOOP AT t_selected INTO DATA(id).
      DATA(doc) = t_docs[ documentid = id ].
      IF doc-isdirectory = abap_true.
        CONTINUE.
      ENDIF.
      files = files + 1.
      IF doc-url IS NOT INITIAL.
        client->follow_up_action( val   = client->cs_event-download_b64_file
                                  t_arg = VALUE #( ( doc-url ) ( doc-filename ) ) ).
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
    DATA(target) = current_id.
    DATA(inside) = ``.
    DATA(selected_folders) = 0.
    LOOP AT t_selected INTO DATA(id).
      IF t_docs[ documentid = id ]-isdirectory = abap_true.
        selected_folders = selected_folders + 1.
        target = id.
      ENDIF.
    ENDLOOP.
    IF selected_folders = 1.
      inside = t_docs[ documentid = target ]-filename.
    ELSE.
      target = current_id.
    ENDIF.
    IF line_exists( t_docs[ parentid = target filename = name ] ).
      client->message_toast_display( `A folder with this name already exists` ).
      RETURN.
    ENDIF.
    new_no = new_no + 1.
    DATA(folder) = VALUE ty_s_doc( parentid     = target
                                   documentid   = |folder-new-{ new_no }|
                                   filename     = name
                                   isdirectory  = abap_true
                                   uploadeddate = |{ sy-datum DATE = ISO }|
                                   uploadedby   = `Current User`
                                   status       = `Active`
                                   documenttype = `Folder`
                                   color        = `#ffffff`
                                   bgcolor      = `#30914c`
                                   uploadstate  = `Complete` ).
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

    " bindTableItems on the folder's items, the Breadcrumbs history up to its
    " parent and the folder as the current location; initial is the root
    current_id = id.
    t_history  = VALUE #( ).
    IF id IS INITIAL.
      currentlocationtext = `Attachments`.
    ELSE.
      currentlocationtext = t_docs[ documentid = id ]-filename.
      DATA(parent) = t_docs[ documentid = id ]-parentid.
      WHILE parent IS NOT INITIAL.
        INSERT VALUE #( name = t_docs[ documentid = parent ]-filename path = parent ) INTO t_history INDEX 1.
        parent = t_docs[ documentid = parent ]-parentid.
      ENDWHILE.
      INSERT VALUE #( name = `Attachments` ) INTO t_history INDEX 1.
    ENDIF.
    rows_build( ).
    " the rebound rows start without a selection
    t_selected        = VALUE #( ).
    download_enabled  = abap_false.
    rename_enabled    = abap_false.
    removeall_enabled = abap_false.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `table-uploadSet` ) ( `clearSelection` ) ) ).

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
    DATA(deleted) = 0.
    LOOP AT t_selected INTO DATA(id).
      IF line_exists( t_docs[ documentid = id parentid = current_id ] ).
        doc_delete( id ).
        deleted = deleted + 1.
      ENDIF.
    ENDLOOP.
    IF deleted = 0.
      client->message_toast_display( `No items were found to delete` ).
      RETURN.
    ENDIF.
    t_selected = VALUE #( ).
    rows_build( ).
    client->message_toast_display( |{ deleted } item(s) deleted successfully| ).

  ENDMETHOD.


  METHOD rows_build.

    " the open folder's subtree as the TreeTable's rows
    t_items = VALUE #( ).
    LOOP AT t_docs INTO DATA(doc1) WHERE parentid = current_id.
      DATA(level1) = CORRESPONDING ty_s_level1( doc1 ).
      LOOP AT t_docs INTO DATA(doc2) WHERE parentid = doc1-documentid.
        DATA(level2) = CORRESPONDING ty_s_level2( doc2 ).
        LOOP AT t_docs INTO DATA(doc3) WHERE parentid = doc2-documentid.
          DATA(level3) = CORRESPONDING ty_s_level3( doc3 ).
          LOOP AT t_docs INTO DATA(doc4) WHERE parentid = doc3-documentid.
            INSERT CORRESPONDING ty_s_level4( doc4 ) INTO TABLE level3-items.
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
    DATA(parent) = current_id.
    DATA(levels) = path_indices( path ).
    LOOP AT levels INTO DATA(index).
      result = ``.
      DATA(position) = 0.
      LOOP AT t_docs INTO DATA(doc) WHERE parentid = parent.
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
    LOOP AT t_docs INTO DATA(child) WHERE parentid = id.
      doc_delete( child-documentid ).
    ENDLOOP.
    DELETE t_docs WHERE documentid = id.

  ENDMETHOD.


  METHOD doc_insert.

    " unshift into the parent's items - or, for an uploaded file, in front of
    " its first file (behind the folders)
    LOOP AT t_docs INTO DATA(sibling) WHERE parentid = doc-parentid.
      IF after_folders = abap_false OR sibling-isdirectory = abap_false.
        INSERT doc INTO t_docs INDEX sy-tabix.
        RETURN.
      ENDIF.
    ENDLOOP.
    INSERT doc INTO TABLE t_docs.

  ENDMETHOD.


  METHOD path_indices.

    SPLIT path AT `/` INTO TABLE DATA(parts).
    LOOP AT parts INTO DATA(part).
      IF part IS NOT INITIAL AND part CO `0123456789`.
        INSERT CONV i( part ) + 1 INTO TABLE result.
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

    " UploadSetwithTable.getIconForFileType: IconPool's media type table, or the
    " file extension when there is no media type
    IF mediatype IS NOT INITIAL.
      DATA(type) = to_lower( mediatype ).
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

    DATA(dot) = find( val = filename sub = `.` occ = -1 ).
    IF dot < 0.
      result = `sap-icon://document`.
      RETURN.
    ENDIF.
    DATA(extension) = to_lower( substring( val = filename off = dot + 1 ) ).
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
    DATA(bytes) = CONV decfloat34( size ).
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
    t_docs = VALUE #(
      ( documentid = `folder-1` filename = `My Documents` isdirectory = abap_true
        size = 0 uploadeddate = `2023-01-15` uploadedby = `System` status = `Active` documenttype = `Folder`
        color = `#ffffff` bgcolor = `#30914c` )
      ( parentid = `folder-1` documentid = `folder-images` filename = `Images` isdirectory = abap_true
        size = 0 uploadeddate = `2023-02-10` uploadedby = `User` status = `Active` documenttype = `Folder`
        color = `#ffffff` bgcolor = `#30914c` )
      ( parentid = `folder-images` documentid = `img-001` filename = `Animation.gif` mimetype = `image/gif` isdirectory = abap_false
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`
        size = 1048576 uploadeddate = `2023-03-05` uploadedby = `John Doe` status = `Complete` documenttype = `Image`
        previewable = abap_true )
      ( parentid = `folder-images` documentid = `folder-screenshots` filename = `Screenshots` isdirectory = abap_true
        size = 0 uploadeddate = `2023-04-01` uploadedby = `User` status = `Active` documenttype = `Folder`
        color = `#ffffff` bgcolor = `#30914c` )
      ( parentid = `folder-screenshots` documentid = `screenshot-001` filename = `Video.mp4` mimetype = `video/mp4` isdirectory = abap_false
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Video.mp4`
        size = 42000000 uploadeddate = `2023-04-01` uploadedby = `Current User` status = `Complete` documenttype = `Video`
        previewable = abap_true )
      ( parentid = `folder-1` documentid = `folder-reports` filename = `Reports` isdirectory = abap_true
        size = 0 uploadeddate = `2023-02-15` uploadedby = `Admin` status = `Active` documenttype = `Folder`
        color = `#ffffff` bgcolor = `#30914c` )
      ( parentid = `folder-reports` documentid = `report-001` filename = `Instructions.pdf` mimetype = `application/pdf` isdirectory = abap_false
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Instructions.pdf`
        size = 30000 uploadeddate = `2023-04-01` uploadedby = `Finance Team` status = `Complete` documenttype = `Document`
        previewable = abap_true )
      ( parentid = `folder-reports` documentid = `report-002` filename = `Business Plan Agenda.doc` mimetype = `application/msword` isdirectory = abap_false
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Agenda.doc`
        size = 200000 uploadeddate = `2023-04-02` uploadedby = `Planning Team` status = `Complete` documenttype = `Document`
        previewable = abap_true )
      ( parentid = `folder-1` documentid = `doc-002` filename = `Third Quarter Results.ppt` mimetype = `application/vnd.ms-powerpoint` isdirectory = abap_false
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Third Quarter Results.ppt`
        size = 3145728 uploadeddate = `2023-03-15` uploadedby = `Support Team` status = `Complete` documenttype = `Presentation`
        previewable = abap_true )
      ( documentid = `doc-001` filename = `Document.txt` mimetype = `text/plain` isdirectory = abap_false
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Document.txt`
        size = 420 uploadeddate = `2023-02-20` uploadedby = `User` status = `Complete` documenttype = `Document`
        previewable = abap_true )
      ( documentid = `doc-003` filename = `Business Plan Topics.xls` mimetype = `application/vnd.ms-excel` isdirectory = abap_false
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Topics.xls`
        size = 1048576 uploadeddate = `2023-03-20` uploadedby = `Marketing` status = `In work` documenttype = `Spreadsheet`
        previewable = abap_true )
      ( documentid = `doc-004` filename = `sample-zip-file.zip` mimetype = `application/zip` isdirectory = abap_false
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/sample-zip-file.zip`
        size = 42000 uploadeddate = `2023-03-25` uploadedby = `Development Team` status = `Complete` documenttype = `Archive` )
      ( documentid = `folder-temp` filename = `Temporary Files` isdirectory = abap_true
        size = 0 uploadeddate = `2023-04-01` uploadedby = `System` status = `Active` documenttype = `Folder`
        color = `#ffffff` bgcolor = `#30914c` )
      ( parentid = `folder-temp` documentid = `temp-001` filename = `Notes.txt` mimetype = `text/plain` isdirectory = abap_false
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Notes.txt`
        size = 2048 uploadeddate = `2023-04-01` uploadedby = `System` status = `Complete` documenttype = `Document`
        previewable = abap_true ) ).
    LOOP AT t_docs REFERENCE INTO DATA(doc).
      row_derive( CHANGING row = doc->* ).
    ENDLOOP.
    folder_open( `` ).

  ENDMETHOD.

ENDCLASS.
