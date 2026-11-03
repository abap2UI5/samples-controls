" @keywords uploadsetwithtable upload setwith table sap.m.plugins uploadsetwithtableplugin.multipleplugininstances dynamicpage vbox overflowtoolbar title toolbarspacer searchfield
" @summary This example demonstrates the usage of multiple plugin instances with multiple tables. The plugin instances are created for each table and the uploaded files are displayed in their respective tables.
" @origin sap.m.sample.UploadSetwithTablePlugin.MultiplePluginInstances - https://sdk.openui5.org/entity/sap.m.plugins.UploadSetwithTable/sample/sap.m.sample.UploadSetwithTablePlugin.MultiplePluginInstances (status: generated)
CLASS z2ui5_cl_smpc_app_655 DEFINITION PUBLIC.

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
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
    " the three arrays of documents.json, one per table
    DATA t_items          TYPE ty_t_item.
    DATA t_itemsinstance2 TYPE ty_t_item.
    DATA t_itemsinstance3 TYPE ty_t_item.
    " onSelectionChange: each table's Download button follows its selection
    DATA download_enabled  TYPE abap_bool.
    DATA download_enabled2 TYPE abap_bool.
    DATA download_enabled3 TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    DATA remove_path TYPE string.
    DATA upload_no   TYPE i.

    METHODS view_display.
    METHODS on_event.
    METHODS row_new
      IMPORTING
        filename      TYPE string
        mediatype     TYPE string
        filesize      TYPE i
      RETURNING
        VALUE(result) TYPE ty_s_item.
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


CLASS z2ui5_cl_smpc_app_655 IMPLEMENTATION.

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
    DATA temp9 TYPE string_table.
    DATA temp10 TYPE string_table.
    DATA temp11 TYPE string_table.
    DATA temp12 TYPE string_table.
    DATA temp13 TYPE string_table.
    DATA temp14 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp15 TYPE string_table.
    DATA temp16 TYPE string_table.
    DATA temp17 TYPE string_table.
    DATA temp18 TYPE string_table.
    DATA temp19 TYPE string_table.
    DATA temp20 TYPE string_table.
    DATA temp21 TYPE string_table.
    DATA temp22 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp23 TYPE string_table.
    DATA temp24 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `IMAGEURL` INTO TABLE temp1.
    INSERT `UPLOADSTATE` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `$event.oSource.getId()` INTO TABLE temp2.
    INSERT `$event.oSource.getSelectedContexts().length` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `table-uploadSet` INTO TABLE temp3.
    INSERT `items` INTO TABLE temp3.
    INSERT `filter` INTO TABLE temp3.
    INSERT `FILENAME` INTO TABLE temp3.
    INSERT `Contains` INTO TABLE temp3.
    INSERT `${$source>/value}` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `uploadSetPlugin` INTO TABLE temp4.
    INSERT `download` INTO TABLE temp4.
    INSERT `$controller.getView().byId('table-uploadSet').getSelectedContexts()[0]` INTO TABLE temp4.
    INSERT `true` INTO TABLE temp4.
    
    CLEAR temp5.
    INSERT `${$parameters>/item}.getFileName()` INTO TABLE temp5.
    INSERT `${$parameters>/item}.getMediaType()` INTO TABLE temp5.
    INSERT `${$parameters>/item}.getFileObject().size` INTO TABLE temp5.
    INSERT `$event.oSource.data('itemsPath')` INTO TABLE temp5.
    
    CLEAR temp6.
    temp6-check_prevent_default = abap_true.
    temp6-check_queue_last = abap_true.
    
    CLEAR temp7.
    INSERT `uploadSetPlugin` INTO TABLE temp7.
    INSERT `openFilePreview` INTO TABLE temp7.
    INSERT `$event.oSource.getBindingContext()` INTO TABLE temp7.
    
    CLEAR temp8.
    INSERT `$event.oSource.getBindingContext().getPath()` INTO TABLE temp8.
    INSERT `${FILENAME}` INTO TABLE temp8.
    
    CLEAR temp9.
    INSERT `IMAGEURL` INTO TABLE temp9.
    INSERT `UPLOADSTATE` INTO TABLE temp9.
    
    CLEAR temp10.
    INSERT `$event.oSource.getId()` INTO TABLE temp10.
    INSERT `$event.oSource.getSelectedContexts().length` INTO TABLE temp10.
    
    CLEAR temp11.
    INSERT `table-uploadSet` INTO TABLE temp11.
    INSERT `items` INTO TABLE temp11.
    INSERT `filter` INTO TABLE temp11.
    INSERT `FILENAME` INTO TABLE temp11.
    INSERT `Contains` INTO TABLE temp11.
    INSERT `${$source>/value}` INTO TABLE temp11.
    
    CLEAR temp12.
    INSERT `uploadSetPlugin-instance2` INTO TABLE temp12.
    INSERT `download` INTO TABLE temp12.
    INSERT `$controller.getView().byId('table-uploadSet-instance2').getSelectedContexts()[0]` INTO TABLE temp12.
    INSERT `true` INTO TABLE temp12.
    
    CLEAR temp13.
    INSERT `${$parameters>/item}.getFileName()` INTO TABLE temp13.
    INSERT `${$parameters>/item}.getMediaType()` INTO TABLE temp13.
    INSERT `${$parameters>/item}.getFileObject().size` INTO TABLE temp13.
    INSERT `$event.oSource.data('itemsPath')` INTO TABLE temp13.
    
    CLEAR temp14.
    temp14-check_prevent_default = abap_true.
    temp14-check_queue_last = abap_true.
    
    CLEAR temp15.
    INSERT `uploadSetPlugin-instance2` INTO TABLE temp15.
    INSERT `openFilePreview` INTO TABLE temp15.
    INSERT `$event.oSource.getBindingContext()` INTO TABLE temp15.
    
    CLEAR temp16.
    INSERT `$event.oSource.getBindingContext().getPath()` INTO TABLE temp16.
    INSERT `${FILENAME}` INTO TABLE temp16.
    
    CLEAR temp17.
    INSERT `IMAGEURL` INTO TABLE temp17.
    INSERT `UPLOADSTATE` INTO TABLE temp17.
    
    CLEAR temp18.
    INSERT `$event.oSource.getId()` INTO TABLE temp18.
    INSERT `$event.oSource.getSelectedContexts().length` INTO TABLE temp18.
    
    CLEAR temp19.
    INSERT `table-uploadSet` INTO TABLE temp19.
    INSERT `items` INTO TABLE temp19.
    INSERT `filter` INTO TABLE temp19.
    INSERT `FILENAME` INTO TABLE temp19.
    INSERT `Contains` INTO TABLE temp19.
    INSERT `${$source>/value}` INTO TABLE temp19.
    
    CLEAR temp20.
    INSERT `uploadSetPlugin-instance3` INTO TABLE temp20.
    INSERT `download` INTO TABLE temp20.
    INSERT `$controller.getView().byId('table-uploadSet-instance3').getSelectedContexts()[0]` INTO TABLE temp20.
    INSERT `true` INTO TABLE temp20.
    
    CLEAR temp21.
    INSERT `${$parameters>/item}.getFileName()` INTO TABLE temp21.
    INSERT `${$parameters>/item}.getMediaType()` INTO TABLE temp21.
    INSERT `${$parameters>/item}.getFileObject().size` INTO TABLE temp21.
    INSERT `$event.oSource.data('itemsPath')` INTO TABLE temp21.
    
    CLEAR temp22.
    temp22-check_prevent_default = abap_true.
    temp22-check_queue_last = abap_true.
    
    CLEAR temp23.
    INSERT `uploadSetPlugin-instance3` INTO TABLE temp23.
    INSERT `openFilePreview` INTO TABLE temp23.
    INSERT `$event.oSource.getBindingContext()` INTO TABLE temp23.
    
    CLEAR temp24.
    INSERT `$event.oSource.getBindingContext().getPath()` INTO TABLE temp24.
    INSERT `${FILENAME}` INTO TABLE temp24.
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
                )->ele( `VBox`
                    )->ele( `Table`
                        )->a( n = `id`              v = `table-uploadSet`
                        )->a( n = `sticky`          v = `ColumnHeaders,HeaderToolbar`
                        )->a( n = `width`           v = `auto`
                        )->a( n = `mode`            v = `MultiSelect`
                        )->a( n = `fixedLayout`     v = `false`
                        )->a( n = `inset`           v = `true`
                        )->a( n = `autoPopinMode`   v = `true`
                        )->a( n = `hiddenInPopin`   v = `None`
                        )->a( n = `items`           v = |\{ path: '{ client->_bind( val                = t_items
                                                                                    path               = abap_true
                                                                                    omit_initial_paths = temp1 ) }', templateShareable: false \}|
                        )->a( n = `selectionChange` v = client->_event( val   = `SELECTION`
                                                                        t_arg = temp2 )

                        )->ele( `headerToolbar`
                            )->ele( `OverflowToolbar`
                                )->tag( `Title`
                                    )->a( n = `text`  v = |Documents (\{= ${ client->_bind( t_items ) }.length\})|
                                    )->a( n = `level` v = `H2`
                                )->tag( `ToolbarSpacer`

                                " onSearch filters the FIRST table whichever field is typed in
                                )->ele( `SearchField`
                                    )->a( n = `width`      v = `20%`
                                    )->a( n = `liveChange` v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                                         t_arg = temp3 )

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
                                                                                      t_arg = temp4 )

                            )->end(
                        )->end(
                        )->ele( `dependents`
                            )->ele( n = `UploadSetwithTable` ns = `plugins`
                                )->a( n = `id`                     v = `uploadSetPlugin`
                                )->a( n = `uploadUrl`              v = `/uploadFiles`
                                )->a( n = `multiple`               v = `true`
                                )->a( n = `beforeUploadStarts`     v = client->_event( val    = `UPLOAD`
                                                                                       t_arg  = temp5
                                                                                       s_ctrl = temp6 )
                                )->a( n = `cloudFilePickerEnabled` v = `true`
                                )->a( n = `actions`                v = `uploadButton`

                                )->ele( n = `rowConfiguration` ns = `plugins`
                                    )->tag( n = `UploadItemConfiguration` ns = `upload`
                                        )->a( n = `fileNamePath`        v = `FILENAME`
                                        )->a( n = `mediaTypePath`       v = `MEDIATYPE`
                                        )->a( n = `urlPath`             v = `URL`
                                        )->a( n = `previewablePath`     v = `PREVIEWABLE`
                                        )->a( n = `fileSizePath`        v = `FILESIZE`
                                        )->a( n = `isTrustedSourcePath` v = `TRUSTEDSOURCE`

                                )->end(
                                )->ele( n = `customData` ns = `plugins`
                                    )->tag( n = `CustomData` ns = `core`
                                        )->a( n = `key`        v = `itemsPath`
                                        )->a( n = `value`      v = `items`
                                        )->a( n = `writeToDom` v = `false`

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
                                        )->tag( n = `Icon` ns = `core`
                                            )->a( n = `src`     v = `{ICON}`
                                            )->a( n = `visible` v = `{= ${IMAGEURL} === undefined || ${IMAGEURL} === '' }`
                                            )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`

                                        )->ele( `VBox`
                                            )->a( n = `class` v = `sapUiTinyMargin sapUiSmallMarginBegin`

                                            )->tag( `Link`
                                                )->a( n = `text`  v = `{FILENAME}`
                                                )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                                t_arg = temp7 )
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
                                        )->a( n = `press` v = client->_event( val   = `REMOVE_ROW`
                                                                              t_arg = temp8 )

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                    )->ele( `Table`
                        )->a( n = `id`              v = `table-uploadSet-instance2`
                        )->a( n = `sticky`          v = `ColumnHeaders,HeaderToolbar`
                        )->a( n = `width`           v = `auto`
                        )->a( n = `mode`            v = `MultiSelect`
                        )->a( n = `fixedLayout`     v = `false`
                        )->a( n = `inset`           v = `true`
                        )->a( n = `autoPopinMode`   v = `true`
                        )->a( n = `hiddenInPopin`   v = `None`
                        )->a( n = `items`           v = |\{ path: '{ client->_bind( val                = t_itemsinstance2
                                                                                    path               = abap_true
                                                                                    omit_initial_paths = temp9 ) }', templateShareable: false \}|
                        )->a( n = `selectionChange` v = client->_event( val   = `SELECTION`
                                                                        t_arg = temp10 )

                        )->ele( `headerToolbar`
                            )->ele( `OverflowToolbar`
                                )->tag( `Title`
                                    )->a( n = `text`  v = |Documents (\{= ${ client->_bind( t_itemsinstance2 ) }.length\})|
                                    )->a( n = `level` v = `H2`
                                )->tag( `ToolbarSpacer`

                                " onSearch filters the FIRST table whichever field is typed in
                                )->ele( `SearchField`
                                    )->a( n = `width`      v = `20%`
                                    )->a( n = `liveChange` v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                                         t_arg = temp11 )

                                    )->ele( `layoutData`
                                        )->tag( `OverflowToolbarLayoutData`
                                            )->a( n = `priority` v = `NeverOverflow`

                                    )->end(
                                )->end(
                                )->tag( `ToolbarSeparator`
                                )->tag( n = `ActionsPlaceholder` ns = `upload`
                                    )->a( n = `id`             v = `uploadButtonInstance2`
                                    )->a( n = `placeholderFor` v = `UploadButtonPlaceholder`
                                )->tag( `Button`
                                    )->a( n = `id`      v = `downloadSelectedButton-instance2`
                                    )->a( n = `text`    v = `Download`
                                    )->a( n = `enabled` v = client->_bind( download_enabled2 )
                                    )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                      t_arg = temp12 )

                            )->end(
                        )->end(
                        )->ele( `dependents`
                            )->ele( n = `UploadSetwithTable` ns = `plugins`
                                )->a( n = `id`                     v = `uploadSetPlugin-instance2`
                                )->a( n = `uploadUrl`              v = `/uploadFiles`
                                )->a( n = `multiple`               v = `true`
                                )->a( n = `beforeUploadStarts`     v = client->_event( val    = `UPLOAD`
                                                                                       t_arg  = temp13
                                                                                       s_ctrl = temp14 )
                                )->a( n = `cloudFilePickerEnabled` v = `true`
                                )->a( n = `actions`                v = `uploadButtonInstance2`

                                )->ele( n = `rowConfiguration` ns = `plugins`
                                    )->tag( n = `UploadItemConfiguration` ns = `upload`
                                        )->a( n = `fileNamePath`        v = `FILENAME`
                                        )->a( n = `mediaTypePath`       v = `MEDIATYPE`
                                        )->a( n = `urlPath`             v = `URL`
                                        )->a( n = `previewablePath`     v = `PREVIEWABLE`
                                        )->a( n = `fileSizePath`        v = `FILESIZE`
                                        )->a( n = `isTrustedSourcePath` v = `TRUSTEDSOURCE`

                                )->end(
                                )->ele( n = `customData` ns = `plugins`
                                    )->tag( n = `CustomData` ns = `core`
                                        )->a( n = `key`        v = `itemsPath`
                                        )->a( n = `value`      v = `items-instance2`
                                        )->a( n = `writeToDom` v = `false`

                                )->end(
                            )->end(
                        )->end(
                        )->ele( `columns`
                            )->ele( `Column`
                                )->a( n = `id`         v = `fileName-instance2`
                                )->a( n = `importance` v = `High`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `File Name`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `id-instance-2`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `ID`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `revision-instance2`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Revision`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `status-instance2`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Status`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `fileSize-instance2`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `File Size`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `lastModified-instance2`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Last Modified`

                                )->end(
                            )->end(
                            )->tag( `Column`
                                )->a( n = `id`         v = `actionButton-instance2`
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
                                        )->tag( n = `Icon` ns = `core`
                                            )->a( n = `src`     v = `{ICON}`
                                            )->a( n = `visible` v = `{= ${IMAGEURL} === undefined || ${IMAGEURL} === '' }`
                                            )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`

                                        )->ele( `VBox`
                                            )->a( n = `class` v = `sapUiTinyMargin sapUiSmallMarginBegin`

                                            )->tag( `Link`
                                                )->a( n = `text`  v = `{FILENAME}`
                                                )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                                t_arg = temp15 )
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
                                        )->a( n = `press` v = client->_event( val   = `REMOVE_ROW`
                                                                              t_arg = temp16 )

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                    )->ele( `Table`
                        )->a( n = `id`              v = `table-uploadSet-instance3`
                        )->a( n = `sticky`          v = `ColumnHeaders,HeaderToolbar`
                        )->a( n = `width`           v = `auto`
                        )->a( n = `mode`            v = `MultiSelect`
                        )->a( n = `fixedLayout`     v = `false`
                        )->a( n = `inset`           v = `true`
                        )->a( n = `autoPopinMode`   v = `true`
                        )->a( n = `hiddenInPopin`   v = `None`
                        )->a( n = `items`           v = |\{ path: '{ client->_bind( val                = t_itemsinstance3
                                                                                    path               = abap_true
                                                                                    omit_initial_paths = temp17 ) }', templateShareable: false \}|
                        )->a( n = `selectionChange` v = client->_event( val   = `SELECTION`
                                                                        t_arg = temp18 )

                        )->ele( `headerToolbar`
                            )->ele( `OverflowToolbar`
                                )->tag( `Title`
                                    )->a( n = `text`  v = |Documents (\{= ${ client->_bind( t_itemsinstance3 ) }.length\})|
                                    )->a( n = `level` v = `H2`
                                )->tag( `ToolbarSpacer`

                                " onSearch filters the FIRST table whichever field is typed in
                                )->ele( `SearchField`
                                    )->a( n = `width`      v = `20%`
                                    )->a( n = `liveChange` v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                                         t_arg = temp19 )

                                    )->ele( `layoutData`
                                        )->tag( `OverflowToolbarLayoutData`
                                            )->a( n = `priority` v = `NeverOverflow`

                                    )->end(
                                )->end(
                                )->tag( `ToolbarSeparator`
                                )->tag( n = `ActionsPlaceholder` ns = `upload`
                                    )->a( n = `id`             v = `uploadButtonInstance3`
                                    )->a( n = `placeholderFor` v = `UploadButtonPlaceholder`
                                )->tag( `Button`
                                    )->a( n = `id`      v = `downloadSelectedButton-instance3`
                                    )->a( n = `text`    v = `Download`
                                    )->a( n = `enabled` v = client->_bind( download_enabled3 )
                                    )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                      t_arg = temp20 )

                            )->end(
                        )->end(
                        )->ele( `dependents`
                            )->ele( n = `UploadSetwithTable` ns = `plugins`
                                )->a( n = `id`                     v = `uploadSetPlugin-instance3`
                                )->a( n = `uploadUrl`              v = `/uploadFiles`
                                )->a( n = `multiple`               v = `true`
                                )->a( n = `beforeUploadStarts`     v = client->_event( val    = `UPLOAD`
                                                                                       t_arg  = temp21
                                                                                       s_ctrl = temp22 )
                                )->a( n = `cloudFilePickerEnabled` v = `true`
                                )->a( n = `actions`                v = `uploadButtonInstance3`

                                )->ele( n = `rowConfiguration` ns = `plugins`
                                    )->tag( n = `UploadItemConfiguration` ns = `upload`
                                        )->a( n = `fileNamePath`        v = `FILENAME`
                                        )->a( n = `mediaTypePath`       v = `MEDIATYPE`
                                        )->a( n = `urlPath`             v = `URL`
                                        )->a( n = `previewablePath`     v = `PREVIEWABLE`
                                        )->a( n = `fileSizePath`        v = `FILESIZE`
                                        )->a( n = `isTrustedSourcePath` v = `TRUSTEDSOURCE`

                                )->end(
                                )->ele( n = `customData` ns = `plugins`
                                    )->tag( n = `CustomData` ns = `core`
                                        )->a( n = `key`        v = `itemsPath`
                                        )->a( n = `value`      v = `items-instance3`
                                        )->a( n = `writeToDom` v = `false`

                                )->end(
                            )->end(
                        )->end(
                        )->ele( `columns`
                            )->ele( `Column`
                                )->a( n = `id`         v = `fileName-instance3`
                                )->a( n = `importance` v = `High`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `File Name`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `id-instance3`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `ID`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `revision-instance3`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Revision`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `status-instance3`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Status`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `fileSize-instance3`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `File Size`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `lastModified-instance3`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Last Modified`

                                )->end(
                            )->end(
                            )->tag( `Column`
                                )->a( n = `id`         v = `actionButton-instance3`
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
                                        )->tag( n = `Icon` ns = `core`
                                            )->a( n = `src`     v = `{ICON}`
                                            )->a( n = `visible` v = `{= ${IMAGEURL} === undefined || ${IMAGEURL} === '' }`
                                            )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`

                                        )->ele( `VBox`
                                            )->a( n = `class` v = `sapUiTinyMargin sapUiSmallMarginBegin`

                                            )->tag( `Link`
                                                )->a( n = `text`  v = `{FILENAME}`
                                                )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                                t_arg = temp23 )
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
                                        )->a( n = `press` v = client->_event( val   = `REMOVE_ROW`
                                                                              t_arg = temp24 ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA table_id TYPE string.
        DATA selected TYPE abap_bool.
        DATA temp1 TYPE xsdboolean.
        DATA temp3 TYPE string_table.
          DATA index TYPE i.
          DATA temp5 TYPE string_table.
        DATA temp7 TYPE i.
        DATA row TYPE z2ui5_cl_smpc_app_655=>ty_s_item.

    CASE client->get_event( ).

      WHEN `SELECTION`.
        " onSelectionChange tells the three tables apart by their ids
        
        table_id = client->get_event_arg( ).
        
        
        temp1 = boolc( client->get_event_arg( 2 ) > 0 ).
        selected = temp1.
        IF table_id CS `instance2`.
          download_enabled2 = selected.
        ELSEIF table_id CS `instance3`.
          download_enabled3 = selected.
        ELSE.
          download_enabled = selected.
        ENDIF.

      WHEN `REMOVE_ROW`.
        " removeItem - MessageBox.warning; the icon is the warning box's own
        remove_path = client->get_event_arg( ).
        
        CLEAR temp3.
        INSERT `Remove` INTO TABLE temp3.
        INSERT `CANCEL` INTO TABLE temp3.
        client->message_box_display( text             = |Are you sure you want to remove the document { client->get_event_arg( 2 ) } ?|
                                     type             = `warning`
                                     actions          = temp3
                                     emphasizedaction = `Remove`
                                     styleclass       = `sapMUSTRemovePopoverContainer`
                                     initialfocus     = `CANCEL`
                                     onclose          = `REMOVE_CLOSE` ).

      WHEN `REMOVE_CLOSE`.
        " as in the sample, the row's index is spliced out of /items and the
        " first table's selection is cleared, whichever table the row was in
        IF client->get_event_arg( ) = `Remove`.
          
          index = row_index( remove_path ).
          IF index BETWEEN 1 AND lines( t_items ).
            DELETE t_items INDEX index.
          ENDIF.
          
          CLEAR temp5.
          INSERT `table-uploadSet` INTO TABLE temp5.
          INSERT `removeSelections` INTO TABLE temp5.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = temp5 ).
          download_enabled = abap_false.
        ENDIF.

      WHEN `UPLOAD`.
        " the mock server answers into the array the plugin's itemsPath names
        
        temp7 = client->get_event_arg( 3 ).
        
        row = row_new( filename  = client->get_event_arg( )
                             mediatype = client->get_event_arg( 2 )
                             filesize  = temp7 ).
        CASE client->get_event_arg( 4 ).
          WHEN `items-instance2`.
            INSERT row INTO t_itemsinstance2 INDEX 1.
          WHEN `items-instance3`.
            INSERT row INTO t_itemsinstance3 INDEX 1.
          WHEN OTHERS.
            INSERT row INTO t_items INDEX 1.
        ENDCASE.
        client->message_toast_display( `Document Added` ).

    ENDCASE.

  ENDMETHOD.


  METHOD row_new.

    " the mock server's Create branch
    upload_no = upload_no + 1.
    CLEAR result.
    result-id = |{ upload_no }|.
    result-filename = filename.
    result-mediatype = mediatype.
    result-uploadstate = `Complete`.
    result-revision = `00`.
    result-status = `In work`.
    result-filesize = filesize.
    result-lastmodifiedby = `Jane Burns`.
    result-lastmodified = `10/03/21, 10:03:00 PM`.
    result-documenttype = `Invoice`.
    result-trustedsource = abap_true.
    row_derive( CHANGING row = result ).

  ENDMETHOD.


  METHOD row_index.

    " a row's binding path ends in its 0-based index: /T_ITEMS/3 is the 4th row
    DATA slash TYPE i.
    DATA digits TYPE string.
    DATA temp8 TYPE i.
    slash = find( val = path sub = `/` occ = -1 ).
    IF slash < 0.
      RETURN.
    ENDIF.
    
    digits = substring( val = path off = slash + 1 ).
    IF digits IS INITIAL OR digits CN `0123456789`.
      RETURN.
    ENDIF.
    
    temp8 = digits.
    result = temp8 + 1.

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
    DATA temp9 TYPE decfloat34.
    DATA bytes LIKE temp9.
    temp9 = size.
    
    bytes = temp9.
    IF size < kilobyte * kilobyte.
      result = |{ bytes / kilobyte DECIMALS = 2 } KB|.
    ELSEIF size < kilobyte * kilobyte * kilobyte.
      result = |{ bytes / kilobyte / kilobyte DECIMALS = 2 } MB|.
    ELSE.
      result = |{ bytes / kilobyte / kilobyte / kilobyte DECIMALS = 2 } GB|.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " model/documents.json, all three arrays - the document URLs point at the OpenUI5 host
    DATA temp10 TYPE z2ui5_cl_smpc_app_655=>ty_t_item.
    DATA temp11 LIKE LINE OF temp10.
    DATA temp12 TYPE z2ui5_cl_smpc_app_655=>ty_t_item.
    DATA temp13 LIKE LINE OF temp12.
    DATA temp14 TYPE z2ui5_cl_smpc_app_655=>ty_t_item.
    DATA temp15 LIKE LINE OF temp14.
    DATA temp16 LIKE LINE OF t_items.
    DATA row LIKE REF TO temp16.
    CLEAR temp10.
    
    CLEAR temp11.
    temp11-id = `23004569`.
    temp11-filename = `Invoice summary.doc`.
    temp11-mediatype = `application/msword`.
    temp11-imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp11-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Agenda.doc`.
    temp11-revision = `01`.
    temp11-status = `In work`.
    temp11-filesize = 200.
    temp11-lastmodifiedby = `Jane Burns`.
    temp11-lastmodified = `10/03/21, 10:03:00 PM`.
    temp11-documenttype = `Invoice`.
    temp11-previewable = abap_true.
    INSERT temp11 INTO TABLE temp10.
    CLEAR temp11.
    temp11-id = `23004589`.
    temp11-filename = `Business Plan Topics.xls`.
    temp11-mediatype = `application/vnd.ms-excel`.
    temp11-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Topics.xls`.
    temp11-revision = `00`.
    temp11-status = `In work`.
    temp11-filesize = 2400.
    temp11-lastmodifiedby = `Jane Burns`.
    temp11-lastmodified = `10/03/21, 10:03:00 PM`.
    temp11-documenttype = `Invoice`.
    temp11-previewable = abap_true.
    INSERT temp11 INTO TABLE temp10.
    CLEAR temp11.
    temp11-id = `23004578`.
    temp11-filename = `Instructions.pdf`.
    temp11-mediatype = `application/pdf`.
    temp11-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Instructions.pdf`.
    temp11-revision = `01`.
    temp11-status = `In work`.
    temp11-filesize = 30000.
    temp11-lastmodifiedby = `Jane Burns`.
    temp11-lastmodified = `10/03/21, 10:03:00 PM`.
    temp11-documenttype = `Specification`.
    temp11-previewable = abap_true.
    temp11-trustedsource = abap_true.
    INSERT temp11 INTO TABLE temp10.
    t_items = temp10.
    
    CLEAR temp12.
    
    CLEAR temp13.
    temp13-id = `23004579`.
    temp13-filename = `Document.txt`.
    temp13-mediatype = `text/plain`.
    temp13-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Document.txt`.
    temp13-revision = `42`.
    temp13-status = `In work`.
    temp13-filesize = 420.
    temp13-lastmodifiedby = `Jane Burns`.
    temp13-lastmodified = `10/03/21, 10:03:00 PM`.
    temp13-documenttype = `Document`.
    temp13-previewable = abap_true.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-id = `23004581`.
    temp13-filename = `Test Image.png`.
    temp13-mediatype = `image/png`.
    temp13-imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp13-url = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`.
    temp13-revision = `06`.
    temp13-status = `In work`.
    temp13-filesize = 420.
    temp13-lastmodifiedby = `Jane Burns`.
    temp13-lastmodified = `10/03/21, 10:03:00 PM`.
    temp13-documenttype = `Attachment`.
    temp13-previewable = abap_true.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-id = `23004582`.
    temp13-filename = `Test Attachment.gif`.
    temp13-mediatype = `image/gif`.
    temp13-imageurl = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`.
    temp13-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`.
    temp13-revision = `11`.
    temp13-status = `In work`.
    temp13-filesize = 420.
    temp13-lastmodifiedby = `Jane Burns`.
    temp13-lastmodified = `10/03/21, 10:03:00 PM`.
    temp13-documenttype = `Attachment`.
    temp13-previewable = abap_true.
    INSERT temp13 INTO TABLE temp12.
    t_itemsinstance2 = temp12.
    
    CLEAR temp14.
    
    temp15-id = `23004583`.
    temp15-filename = `Test Video.mp4`.
    temp15-mediatype = `video/mp4`.
    temp15-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Video.mp4`.
    temp15-revision = `99`.
    temp15-status = `In work`.
    temp15-filesize = 420000.
    temp15-lastmodifiedby = `Jane Burns`.
    temp15-lastmodified = `10/03/21, 10:03:00 PM`.
    temp15-documenttype = `Attachment`.
    temp15-previewable = abap_true.
    INSERT temp15 INTO TABLE temp14.
    temp15-id = `23004590`.
    temp15-filename = `Sample Zip File.zip`.
    temp15-mediatype = `application/zip`.
    temp15-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/sample-zip-file.zip`.
    temp15-revision = `00`.
    temp15-status = `In work`.
    temp15-filesize = 42000.
    temp15-lastmodifiedby = `Jane Burns`.
    temp15-lastmodified = `10/03/22, 10:20:00 PM`.
    temp15-documenttype = `Attachment`.
    temp15-previewable = abap_true.
    INSERT temp15 INTO TABLE temp14.
    temp15-id = `23004584`.
    temp15-filename = `Transmission.vds`.
    temp15-mediatype = `model/vnd.sap.vds`.
    temp15-url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/transmission.vds`.
    temp15-revision = `42`.
    temp15-status = `In work`.
    temp15-filesize = 123.
    temp15-lastmodifiedby = `Jane Burns`.
    temp15-lastmodified = `10/03/22, 10:20:00 PM`.
    temp15-documenttype = `Attachment`.
    temp15-previewable = abap_true.
    INSERT temp15 INTO TABLE temp14.
    t_itemsinstance3 = temp14.
    
    
    LOOP AT t_items REFERENCE INTO row.
      row_derive( CHANGING row = row->* ).
    ENDLOOP.
    LOOP AT t_itemsinstance2 REFERENCE INTO row.
      row_derive( CHANGING row = row->* ).
    ENDLOOP.
    LOOP AT t_itemsinstance3 REFERENCE INTO row.
      row_derive( CHANGING row = row->* ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
