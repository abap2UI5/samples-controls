" @keywords uploadsetwithtable upload setwith table sap.m.plugins uploadsetwithtableplugin.responsivetablefiledialogs dynamicpage overflowtoolbar title toolbarspacer searchfield overflowtoolbarlayoutdata
" @summary This example demonstrates usage of itemValidationHandler callback to leverage additional validations and configurations for the items that are to be uploaded, and also the manual trigger of the upload process.
" @origin sap.m.sample.UploadSetwithTablePlugin.ResponsiveTableFileDialogs - https://sdk.openui5.org/entity/sap.m.plugins.UploadSetwithTable/sample/sap.m.sample.UploadSetwithTablePlugin.ResponsiveTableFileDialogs (status: generated)
CLASS z2ui5_cl_smpc_app_656 DEFINITION PUBLIC.

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
    TYPES:
      BEGIN OF ty_s_selected,
        filename             TYPE string,
        filecategoryselected TYPE string,
        mediatype            TYPE string,
        filesize             TYPE i,
      END OF ty_s_selected.
    TYPES:
      BEGIN OF ty_s_type,
        categoryid   TYPE string,
        categorytext TYPE string,
      END OF ty_s_type.
    TYPES temp1_cd86fdd896 TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
DATA t_items TYPE temp1_cd86fdd896.
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
    " the FileUpload fragment: the files waiting for their document type
    TYPES temp2_cd86fdd896 TYPE STANDARD TABLE OF ty_s_selected WITH DEFAULT KEY.
DATA t_selecteditems TYPE temp2_cd86fdd896.
    TYPES temp3_cd86fdd896 TYPE STANDARD TABLE OF ty_s_type WITH DEFAULT KEY.
DATA t_types         TYPE temp3_cd86fdd896.
    DATA add_enabled     TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    " the binding paths of the selected rows and of the row a removal asks about
    DATA t_selected  TYPE string_table.
    DATA remove_path TYPE string.
    DATA is_edit     TYPE abap_bool.
    DATA upload_no   TYPE i.

    METHODS view_display.
    METHODS popup_url_display.
    METHODS popup_upload_display.
    METHODS on_event.
    METHODS url_apply.
    METHODS remove_ask
      IMPORTING
        path TYPE string.
    METHODS selection_reset.
    METHODS add_enabled_set.
    METHODS name_valid
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS url_valid
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS row_add
      IMPORTING
        filename     TYPE string
        mediatype    TYPE string
        url          TYPE string
        filesize     TYPE i
        documenttype TYPE string.
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


CLASS z2ui5_cl_smpc_app_656 IMPLEMENTATION.

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
                            " itemValidationHandler is a JS callback - see the sidecar
                            )->a( n = `actions`                v = `uploadButton`

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


  METHOD popup_upload_display.

    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp3 TYPE string_table.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp3.
    INSERT `uploadSetPlugin` INTO TABLE temp3.
    INSERT `fileSelectionHandler` INTO TABLE temp3.
    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`             v = `sap.m`
        )->a( n = `xmlns:core`        v = `sap.ui.core`
        )->a( n = `templateShareable` v = `false`
        )->a( n = `class`             v = `sapUiTinyMarginTop`

        )->ele( `Dialog`
            )->a( n = `title`         v = `Add Document by Upload`
            )->a( n = `contentWidth`  v = `34rem`
            )->a( n = `contentHeight` v = `18rem`
            )->a( n = `class`         v = `sapUiSmallMargin`

            )->ele( `content`
                )->ele( `Toolbar`
                    )->a( n = `class` v = `sapUiTinyMargin`
                    )->a( n = `style` v = `Clear`

                    )->tag( `Title`
                        )->a( n = `text` v = `Documents`
                    )->tag( `ToolbarSpacer`
                    " uploadFilesHandler - the plugin's fileSelectionHandler opens the file dialog
                    )->tag( `Button`
                        )->a( n = `text`  v = `Browse`
                        )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                        t_arg = temp3 )

                )->end(
                )->ele( `Table`
                    )->a( n = `backgroundDesign` v = `Solid`
                    )->a( n = `width`            v = `auto`
                    )->a( n = `fixedLayout`      v = `false`
                    )->a( n = `class`            v = `sapUiTinyMargin sapUiTableBorderVisible`
                    )->a( n = `items`            v = |\{ path: '{ client->_bind( val = t_selecteditems path = abap_true ) }', templateShareable: false \}|

                    )->ele( `columns`
                        )->ele( `Column`
                            )->tag( `Text`
                                )->a( n = `text` v = `Name`

                        )->end(
                        )->ele( `Column`
                            )->tag( `Label`
                                )->a( n = `text`     v = `Type`
                                )->a( n = `required` v = `true`

                        )->end(
                        )->tag( `Column`

                    )->end(
                    )->ele( `items`
                        )->ele( `ColumnListItem`
                            )->ele( `cells`
                                )->tag( `Text`
                                    )->a( n = `text` v = `{FILENAME}`

                                )->ele( `ComboBox`
                                    )->a( n = `items`           v = |\{ path: '{ client->_bind( val = t_types path = abap_true ) }', templateShareable: false \}|
                                    )->a( n = `selectedKey`     v = `{FILECATEGORYSELECTED}`
                                    )->a( n = `selectionChange` v = client->_event( `TYPE_CHANGE` )
                                    )->a( n = `valueState`      v = `{= ${FILECATEGORYSELECTED} ? 'None' : 'Error'}`
                                    )->a( n = `valueStateText`  v = `Select a valid document type`

                                    )->tag( n = `ListItem` ns = `core`
                                        )->a( n = `key`  v = `{CATEGORYID}`
                                        )->a( n = `text` v = `{CATEGORYTEXT}`

                                )->end(
                                " handleRemove reads the item and its reject callback from two
                                " core:CustomData - the row's path is all the backend needs
                                )->tag( `Button`
                                    )->a( n = `type`  v = `Transparent`
                                    )->a( n = `icon`  v = `sap-icon://decline`
                                    )->a( n = `press` v = client->_event( val = `REMOVE_PENDING`
                                                                          arg = `$event.oSource.getBindingContext().getPath()` )

                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(
            )->ele( `beginButton`
                )->tag( `Button`
                    )->a( n = `text`    v = `Add`
                    )->a( n = `type`    v = `Emphasized`
                    )->a( n = `enabled` v = client->_bind( add_enabled )
                    )->a( n = `press`   v = client->_event( `UPLOAD_CONFIRM` )

            )->end(
            )->ele( `endButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `Cancel`
                    )->a( n = `press` v = client->_event( `UPLOAD_CANCEL` ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
          DATA temp5 TYPE string_table.
        DATA temp1 TYPE xsdboolean.
        DATA temp2 TYPE xsdboolean.
        DATA current TYPE i.
        DATA row LIKE LINE OF t_items.
        FIELD-SYMBOLS <temp4> LIKE LINE OF t_items.
        DATA temp6 LIKE sy-tabix.
          DATA target TYPE i.
            FIELD-SYMBOLS <temp6> LIKE LINE OF t_items.
            DATA temp7 LIKE sy-tabix.
            FIELD-SYMBOLS <temp8> LIKE LINE OF t_items.
            DATA temp9 LIKE sy-tabix.
          FIELD-SYMBOLS <temp10> LIKE LINE OF t_selected.
          DATA temp11 LIKE sy-tabix.
          DATA index TYPE i.
        DATA temp12 TYPE z2ui5_cl_smpc_app_656=>ty_s_selected.
        FIELD-SYMBOLS <temp7> LIKE LINE OF t_types.
        DATA temp8 LIKE sy-tabix.
        DATA temp10 TYPE z2ui5_cl_smpc_app_656=>ty_s_selected-filesize.
        DATA renamed TYPE i.
          FIELD-SYMBOLS <temp13> LIKE LINE OF t_items.
          DATA temp14 LIKE sy-tabix.
        DATA pending TYPE i.
        DATA selected LIKE LINE OF t_selecteditems.
        DATA temp15 LIKE t_selecteditems.
        DATA temp16 LIKE t_selecteditems.

    CASE client->get_event( ).

      WHEN `SELECTION`.
        " onSelectionChange - the selected rows arrive as their binding paths
        IF client->get_event_arg( ) IS INITIAL.
          
          CLEAR temp5.
          t_selected = temp5.
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
        READ TABLE t_items INDEX current ASSIGNING <temp4>.
        sy-tabix = temp6.
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
            
            
            temp7 = sy-tabix.
            READ TABLE t_items INDEX target ASSIGNING <temp6>.
            sy-tabix = temp7.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            <temp6>-filename = name_input.
            
            
            temp9 = sy-tabix.
            READ TABLE t_items INDEX target ASSIGNING <temp8>.
            sy-tabix = temp9.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            <temp8>-url      = url_input.
          ENDIF.
          client->popup_destroy( ).
        ENDIF.

      WHEN `REMOVE_SELECTED`.
        IF t_selected IS NOT INITIAL.
          
          
          temp11 = sy-tabix.
          READ TABLE t_selected INDEX 1 ASSIGNING <temp10>.
          sy-tabix = temp11.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          remove_ask( <temp10> ).
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
        " itemValidationCallback - the picked file waits in the FileUpload dialog
        " for its document type, preset to the first category
        
        CLEAR temp12.
        temp12-filename = client->get_event_arg( ).
        
        
        temp8 = sy-tabix.
        READ TABLE t_types INDEX 1 ASSIGNING <temp7>.
        sy-tabix = temp8.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        temp12-filecategoryselected = <temp7>-categoryid.
        temp12-mediatype = client->get_event_arg( 2 ).
        
        temp10 = client->get_event_arg( 3 ).
        temp12-filesize = temp10.
        INSERT temp12 INTO TABLE t_selecteditems.
        add_enabled_set( ).
        popup_upload_display( ).

      WHEN `RENAMED`.
        " onDocumentRenamedSuccess writes the new name into the row
        
        renamed = row_index( client->get_event_arg( ) ).
        IF renamed BETWEEN 1 AND lines( t_items ).
          
          
          temp14 = sy-tabix.
          READ TABLE t_items INDEX renamed ASSIGNING <temp13>.
          sy-tabix = temp14.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp13>-filename = client->get_event_arg( 2 ).
        ENDIF.
        client->message_toast_display( text = `Document Renamed.` duration = `2000` ).

      WHEN `TYPE_CHANGE`.
        " the Add button's isAddButtonEnabled formatter, recomputed per choice
        add_enabled_set( ).

      WHEN `REMOVE_PENDING`.
        " handleRemove - the file leaves the dialog and is not uploaded
        
        pending = row_index( client->get_event_arg( ) ).
        IF pending BETWEEN 1 AND lines( t_selecteditems ).
          DELETE t_selecteditems INDEX pending.
        ENDIF.
        add_enabled_set( ).

      WHEN `UPLOAD_CONFIRM`.
        " handleConfirmation - each file goes up with its document type, and the
        " mock server files it under that type
        
        LOOP AT t_selecteditems INTO selected.
          row_add( filename     = selected-filename
                   mediatype    = selected-mediatype
                   url          = ``
                   filesize     = selected-filesize
                   documenttype = selected-filecategoryselected ).
        ENDLOOP.
        
        CLEAR temp15.
        t_selecteditems = temp15.
        client->popup_destroy( ).
        client->message_toast_display( `Document Added` ).

      WHEN `UPLOAD_CANCEL`.
        " closeFileUplaodFragment
        
        CLEAR temp16.
        t_selecteditems = temp16.
        client->popup_destroy( ).

    ENDCASE.

  ENDMETHOD.


  METHOD url_apply.
        DATA temp17 TYPE string_table.
    DATA has_error TYPE abap_bool.
    DATA temp3 TYPE xsdboolean.

    " handleAddViaUrl
    IF is_edit = abap_true.
      IF name_valid( ) = abap_true.
        " showEditConfirmation - a Message dialog in the Warning state
        
        CLEAR temp17.
        INSERT `Save` INTO TABLE temp17.
        INSERT `DiscardChanges` INTO TABLE temp17.
        client->message_box_display( text             = `You have made changes to this object. What would you like to do?`
                                     type             = `warning`
                                     title            = `Warning`
                                     actions          = temp17
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
      row_add( filename     = name_input
               mediatype    = ``
               url          = url_input
               filesize     = 0
               documenttype = `Invoice` ).
      client->popup_destroy( ).
      client->message_toast_display( `Document Added` ).
    ENDIF.

  ENDMETHOD.


  METHOD remove_ask.

    " removeItem - MessageBox.warning; the icon is the warning box's own
    DATA index TYPE i.
    DATA temp19 TYPE string_table.
    FIELD-SYMBOLS <temp11> LIKE LINE OF t_items.
    DATA temp12 LIKE sy-tabix.
    index = row_index( path ).
    IF index NOT BETWEEN 1 AND lines( t_items ).
      RETURN.
    ENDIF.
    remove_path = path.
    
    CLEAR temp19.
    INSERT `Remove` INTO TABLE temp19.
    INSERT `CANCEL` INTO TABLE temp19.
    
    
    temp12 = sy-tabix.
    READ TABLE t_items INDEX index ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    client->message_box_display( text             = |Are you sure you want to remove the document { <temp11>-filename } ?|
                                 type             = `warning`
                                 actions          = temp19
                                 emphasizedaction = `Remove`
                                 styleclass       = `sapMUSTRemovePopoverContainer`
                                 initialfocus     = `CANCEL`
                                 onclose          = `REMOVE_CLOSE` ).

  ENDMETHOD.


  METHOD selection_reset.

    " oTable.removeSelections( ) - and the buttons follow the empty selection
    DATA temp21 TYPE string_table.
    DATA temp23 TYPE string_table.
    CLEAR temp21.
    INSERT `table-uploadSet` INTO TABLE temp21.
    INSERT `removeSelections` INTO TABLE temp21.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp21 ).
    
    CLEAR temp23.
    t_selected       = temp23.
    download_enabled = abap_false.
    single_enabled   = abap_false.

  ENDMETHOD.


  METHOD add_enabled_set.

    " isAddButtonEnabled - at least one file, and every file has a type
    DATA temp24 LIKE sy-subrc.
    DATA temp4 TYPE xsdboolean.
    READ TABLE t_selecteditems WITH KEY filecategoryselected = `` TRANSPORTING NO FIELDS.
    temp24 = sy-subrc.
    
    temp4 = boolc( t_selecteditems IS NOT INITIAL AND NOT temp24 = 0 ).
    add_enabled = temp4.

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
    DATA temp25 TYPE ty_s_item.
    DATA row LIKE temp25.

    " the mock server's Create branch - unshift the new document
    upload_no = upload_no + 1.
    
    CLEAR temp25.
    temp25-id = |{ upload_no }|.
    temp25-filename = filename.
    temp25-mediatype = mediatype.
    temp25-url = url.
    temp25-uploadstate = `Complete`.
    temp25-revision = `00`.
    temp25-status = `In work`.
    temp25-filesize = filesize.
    temp25-lastmodifiedby = `Jane Burns`.
    temp25-lastmodified = `10/03/21, 10:03:00 PM`.
    temp25-documenttype = documenttype.
    temp25-trustedsource = abap_true.
    
    row = temp25.
    row_derive( CHANGING row = row ).
    INSERT row INTO t_items INDEX 1.

  ENDMETHOD.


  METHOD selected_index.
    FIELD-SYMBOLS <temp26> LIKE LINE OF t_selected.
    DATA temp27 LIKE sy-tabix.

    " the one selected row the toolbar actions work on - 0 when there is none
    IF t_selected IS INITIAL.
      RETURN.
    ENDIF.
    
    
    temp27 = sy-tabix.
    READ TABLE t_selected INDEX 1 ASSIGNING <temp26>.
    sy-tabix = temp27.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    result = row_index( <temp26> ).
    IF result > lines( t_items ).
      result = 0.
    ENDIF.

  ENDMETHOD.


  METHOD row_index.

    " a row's binding path ends in its 0-based index: /T_ITEMS/3 is the 4th row
    DATA slash TYPE i.
    DATA digits TYPE string.
    DATA temp28 TYPE i.
    slash = find( val = path sub = `/` occ = -1 ).
    IF slash < 0.
      RETURN.
    ENDIF.
    
    digits = substring( val = path off = slash + 1 ).
    IF digits IS INITIAL OR digits CN `0123456789`.
      RETURN.
    ENDIF.
    
    temp28 = digits.
    result = temp28 + 1.

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
    DATA temp29 TYPE decfloat34.
    DATA bytes LIKE temp29.
    temp29 = size.
    
    bytes = temp29.
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
    DATA temp30 LIKE t_items.
    DATA temp31 LIKE LINE OF temp30.
    DATA temp32 LIKE LINE OF t_items.
    DATA row LIKE REF TO temp32.
    DATA temp33 LIKE t_types.
    DATA temp34 LIKE LINE OF temp33.
    CLEAR temp30.
    
    CLEAR temp31.
    temp31-id = `23004569`.
    temp31-filename = `Invoice summary.doc`.
    temp31-mediatype = `application/msword`.
    temp31-imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp31-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Agenda.doc`.
    temp31-revision = `01`.
    temp31-status = `In work`.
    temp31-filesize = 200.
    temp31-lastmodifiedby = `Jane Burns`.
    temp31-lastmodified = `10/03/21, 10:03:00 PM`.
    temp31-documenttype = `Invoice`.
    temp31-previewable = abap_true.
    INSERT temp31 INTO TABLE temp30.
    CLEAR temp31.
    temp31-id = `23004589`.
    temp31-filename = `Business Plan Topics.xls`.
    temp31-mediatype = `application/vnd.ms-excel`.
    temp31-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Topics.xls`.
    temp31-revision = `00`.
    temp31-status = `In work`.
    temp31-filesize = 2400.
    temp31-lastmodifiedby = `Jane Burns`.
    temp31-lastmodified = `10/03/21, 10:03:00 PM`.
    temp31-documenttype = `Invoice`.
    temp31-previewable = abap_true.
    INSERT temp31 INTO TABLE temp30.
    CLEAR temp31.
    temp31-id = `23004578`.
    temp31-filename = `Instructions.pdf`.
    temp31-mediatype = `application/pdf`.
    temp31-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Instructions.pdf`.
    temp31-revision = `01`.
    temp31-status = `In work`.
    temp31-filesize = 30000.
    temp31-lastmodifiedby = `Jane Burns`.
    temp31-lastmodified = `10/03/21, 10:03:00 PM`.
    temp31-documenttype = `Specification`.
    temp31-previewable = abap_true.
    temp31-trustedsource = abap_true.
    INSERT temp31 INTO TABLE temp30.
    CLEAR temp31.
    temp31-id = `23004579`.
    temp31-filename = `Document.txt`.
    temp31-mediatype = `text/plain`.
    temp31-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Document.txt`.
    temp31-revision = `42`.
    temp31-status = `In work`.
    temp31-filesize = 420.
    temp31-lastmodifiedby = `Jane Burns`.
    temp31-lastmodified = `10/03/21, 10:03:00 PM`.
    temp31-documenttype = `Document`.
    temp31-previewable = abap_true.
    INSERT temp31 INTO TABLE temp30.
    CLEAR temp31.
    temp31-id = `23004581`.
    temp31-filename = `Test Image.png`.
    temp31-mediatype = `image/png`.
    temp31-imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp31-url = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp31-revision = `06`.
    temp31-status = `In work`.
    temp31-filesize = 420.
    temp31-lastmodifiedby = `Jane Burns`.
    temp31-lastmodified = `10/03/21, 10:03:00 PM`.
    temp31-documenttype = `Attachment`.
    temp31-previewable = abap_true.
    INSERT temp31 INTO TABLE temp30.
    CLEAR temp31.
    temp31-id = `23004582`.
    temp31-filename = `Test Attachment.gif`.
    temp31-mediatype = `image/gif`.
    temp31-imageurl = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`.
    temp31-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`.
    temp31-revision = `11`.
    temp31-status = `In work`.
    temp31-filesize = 420.
    temp31-lastmodifiedby = `Jane Burns`.
    temp31-lastmodified = `10/03/21, 10:03:00 PM`.
    temp31-documenttype = `Attachment`.
    temp31-previewable = abap_true.
    INSERT temp31 INTO TABLE temp30.
    CLEAR temp31.
    temp31-id = `23004583`.
    temp31-filename = `Test Video.mp4`.
    temp31-mediatype = `video/mp4`.
    temp31-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Video.mp4`.
    temp31-revision = `99`.
    temp31-status = `In work`.
    temp31-filesize = 420000.
    temp31-lastmodifiedby = `Jane Burns`.
    temp31-lastmodified = `10/03/21, 10:03:00 PM`.
    temp31-documenttype = `Attachment`.
    temp31-previewable = abap_true.
    INSERT temp31 INTO TABLE temp30.
    CLEAR temp31.
    temp31-id = `23004590`.
    temp31-filename = `Sample Zip File.zip`.
    temp31-mediatype = `application/zip`.
    temp31-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/sample-zip-file.zip`.
    temp31-revision = `00`.
    temp31-status = `In work`.
    temp31-filesize = 42000.
    temp31-lastmodifiedby = `Jane Burns`.
    temp31-lastmodified = `10/03/22, 10:20:00 PM`.
    temp31-documenttype = `Attachment`.
    temp31-previewable = abap_true.
    INSERT temp31 INTO TABLE temp30.
    CLEAR temp31.
    temp31-id = `23004584`.
    temp31-filename = `Transmission.vds`.
    temp31-mediatype = `model/vnd.sap.vds`.
    temp31-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/transmission.vds`.
    temp31-revision = `42`.
    temp31-status = `In work`.
    temp31-filesize = 123.
    temp31-lastmodifiedby = `Jane Burns`.
    temp31-lastmodified = `10/03/22, 10:20:00 PM`.
    temp31-documenttype = `Attachment`.
    temp31-previewable = abap_true.
    INSERT temp31 INTO TABLE temp30.
    t_items = temp30.
    
    
    LOOP AT t_items REFERENCE INTO row.
      row_derive( CHANGING row = row->* ).
    ENDLOOP.

    " getFileCategories - the ComboBox's document types
    
    CLEAR temp33.
    
    temp34-categoryid = `Invoice`.
    temp34-categorytext = `Invoice`.
    INSERT temp34 INTO TABLE temp33.
    temp34-categoryid = `Specification`.
    temp34-categorytext = `Specification`.
    INSERT temp34 INTO TABLE temp33.
    temp34-categoryid = `Attachment`.
    temp34-categorytext = `Attachment`.
    INSERT temp34 INTO TABLE temp33.
    temp34-categoryid = `Legal Document`.
    temp34-categorytext = `Legal Document`.
    INSERT temp34 INTO TABLE temp33.
    t_types = temp33.

  ENDMETHOD.

ENDCLASS.
