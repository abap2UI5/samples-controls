" @keywords responsivesplitter responsive splitter sap.ui.layout panecontainer splitpane splitterlayoutdata panel text list standardlistitem vbox
" @summary ResponsiveSplitter is used to visually divide the content of its parent. It consists of PaneContainers that further agregate other PaneContainers and SplitPanes.
" @origin sap.ui.layout.sample.ResponsiveSplitter - https://sdk.openui5.org/entity/sap.ui.layout.ResponsiveSplitter/sample/sap.ui.layout.sample.ResponsiveSplitter (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_186 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_product,
        productid TYPE string,
        name      TYPE string,
        quantity  TYPE i,
      END OF ty_product.
    DATA productcollection TYPE STANDARD TABLE OF ty_product WITH EMPTY KEY.

    " The original keeps the three pane sizes in a separate 'sizes' JSON model
    " ({sizes>/pane1..3}); with abap2UI5's single default model they live flat
    " here and the SplitterLayoutData.size / the Text labels bind them directly.
    DATA pane1 TYPE string.
    DATA pane2 TYPE string.
    DATA pane3 TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_186 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    " sap.ui.layout.ResponsiveSplitter. The original binds the pane sizes from a
    " separate 'sizes' JSON model ({sizes>/paneN}) and the product list/select
    " from the default model ({/ProductCollection}); abap2UI5 has one default
    " model, so the sizes are folded into it (the 'sizes>' prefix is dropped -
    " last path segment identical, which structural-diff matches). The two
    " PaneContainer 'resize' handlers show an informational MessageToast of the
    " old/new pane sizes. Reproduced roundtrip-free since 2026-08-05: an event
    " arg is a full UI5 expression and .join( ',' ) over an ARRAY parameter
    " resolves (measured with scripts/probes/event-arg-expression-probe.mjs),
    " so both size arrays travel into the client-composed toast 1:1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `height`     v = `100%`

        )->ele( n = `ResponsiveSplitter` ns = `l`
            )->a( n = `defaultPane` v = `default`

            )->ele( n = `PaneContainer` ns = `l`
                )->a( n = `resize` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                 t_arg = VALUE #( ( `MESSAGE_TOAST` )
                                                                                  ( `show` )
                                                                                  ( `Root container is resized.{0}` && |\n| && `New panes sizes = [{1}]` )
                                                                               " the WHOLE 'Old panes sizes' line is conditional in the original
                                                                               " (if (aOldSizes && aOldSizes.length)), not just its value - the first
                                                                               " resize really does arrive with an empty array, since _sizeArraysDiffer
                                                                               " compares [] against the new sizes. So the line is built inside the
                                                                               " expression and the template carries only the placeholder
                                                                               ( `${$parameters>/oldSizes} && ${$parameters>/oldSizes}.length ? '\nOld panes sizes = [' + ${$parameters>/oldSizes}.join(',') + ']' : ''` )
                                                                               ( `${$parameters>/newSizes} ? ${$parameters>/newSizes}.join(',') : ''` ) ) )

                )->ele( n = `SplitPane` ns = `l`
                    )->a( n = `requiredParentWidth` v = `400`
                    )->a( n = `id`                  v = `default`

                    )->ele( n = `layoutData` ns = `l`
                        )->tag( n = `SplitterLayoutData` ns = `l`
                            )->a( n = `size` v = client->_bind( pane1 )

                    )->end(

                    )->ele( `Panel`
                        )->a( n = `headerText` v = `Minimum parent width 400`
                        )->a( n = `height`     v = `100%`

                        )->tag( `Text`
                            )->a( n = `text` v = |LayoutData.size={ client->_bind( pane1 ) }|

                        )->ele( `List`
                            )->a( n = `headerText` v = `Products`
                            )->a( n = `items`      v = client->_bind( productcollection )

                            )->tag( `StandardListItem`
                                )->a( n = `title`   v = `{NAME}`
                                )->a( n = `counter` v = `{QUANTITY}`

                        )->end(
                    )->end(
                )->end(

                )->ele( n = `PaneContainer` ns = `l`
                    )->a( n = `orientation` v = `Vertical`
                    )->a( n = `resize`      v = client->follow_up_action( val   = client->cs_event-control_global
                                                                          t_arg = VALUE #( ( `MESSAGE_TOAST` )
                                                                                           ( `show` )
                                                                                           ( `Inner container is resized.{0}` && |\n| && `New panes sizes = [{1}]` )
                                                                                        " the WHOLE 'Old panes sizes' line is conditional in the original
                                                                                        " (if (aOldSizes && aOldSizes.length)), not just its value - the first
                                                                                        " resize really does arrive with an empty array, since _sizeArraysDiffer
                                                                                        " compares [] against the new sizes. So the line is built inside the
                                                                                        " expression and the template carries only the placeholder
                                                                                        ( `${$parameters>/oldSizes} && ${$parameters>/oldSizes}.length ? '\nOld panes sizes = [' + ${$parameters>/oldSizes}.join(',') + ']' : ''` )
                                                                                        ( `${$parameters>/newSizes} ? ${$parameters>/newSizes}.join(',') : ''` ) ) )

                    )->ele( n = `SplitPane` ns = `l`
                        )->a( n = `requiredParentWidth` v = `600`

                        )->ele( n = `layoutData` ns = `l`
                            )->tag( n = `SplitterLayoutData` ns = `l`
                                )->a( n = `size` v = client->_bind( pane2 )

                        )->end(

                        )->ele( `Panel`
                            )->a( n = `headerText` v = `Minimum parent width 600`

                            )->ele( `VBox`
                                )->tag( `Text`
                                    )->a( n = `text` v = |LayoutData.size={ client->_bind( pane2 ) }|

                                )->ele( `Select`
                                    )->a( n = `forceSelection` v = `false`
                                    )->a( n = `selectedKey`    v = `1239102`
                                    )->a( n = `items`          v = |\{ path: '{ client->_bind_path( productcollection ) }', sorter: \{ path: 'NAME' \} \}|

                                    )->tag( n = `Item` ns = `core`
                                        )->a( n = `key`  v = `{PRODUCTID}`
                                        )->a( n = `text` v = `{NAME}`

                                )->end(
                            )->end(
                        )->end(
                    )->end(

                    )->ele( n = `SplitPane` ns = `l`
                        )->a( n = `requiredParentWidth` v = `800`

                        )->ele( n = `layoutData` ns = `l`
                            )->tag( n = `SplitterLayoutData` ns = `l`
                                )->a( n = `size` v = client->_bind( pane3 )

                        )->end(

                        )->ele( `Page`
                            )->a( n = `title` v = `Minimum parent width 800`

                            )->tag( `Text`
                                )->a( n = `text` v = |LayoutData.size={ client->_bind( pane3 ) }|

                            )->ele( `footer`
                                )->ele( `OverflowToolbar`
                                    )->a( n = `id` v = `otb3`

                                    )->tag( `Label`
                                        )->a( n = `text` v = `Buttons:`
                                    )->tag( `ToolbarSpacer`
                                    )->tag( `Button`
                                        )->a( n = `text` v = `New`
                                        )->a( n = `type` v = `Transparent`
                                    )->tag( `Button`
                                        )->a( n = `text` v = `Open`
                                        )->a( n = `type` v = `Transparent`
                                    )->tag( `Button`
                                        )->a( n = `text` v = `Save`
                                        )->a( n = `type` v = `Transparent`
                                    )->tag( `Button`
                                        )->a( n = `text` v = `Save as`
                                        )->a( n = `type` v = `Transparent`
                                    )->tag( `Button`
                                        )->a( n = `text` v = `Cut`
                                        )->a( n = `type` v = `Transparent`
                                    )->tag( `Button`
                                        )->a( n = `text` v = `Copy`
                                        )->a( n = `type` v = `Transparent`
                                    )->tag( `Button`
                                        )->a( n = `text` v = `Paste`
                                        )->a( n = `type` v = `Transparent`
                                    )->tag( `Button`
                                        )->a( n = `text` v = `Undo`
                                        )->a( n = `type` v = `Transparent` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " the original pane sizes model starts every pane at 'auto'
    pane1 = `auto`.
    pane2 = `auto`.
    pane3 = `auto`.

    " the shared 123-row demo ProductCollection (sap/ui/demo/mock/products.json),
    " projected onto the three columns the sample binds (ProductId, Name, Quantity)
    productcollection = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
