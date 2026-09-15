" @keywords blocklayout block layout sap.ui.layout blocklayoutcustombackgroundpercell html blocklayoutcell text vbox label input textarea
" @summary Block Layout in which all cells use different background color set and different shade.
" @origin sap.ui.layout.sample.BlockLayoutCustomBackgroundPerCell - https://sdk.openui5.org/entity/sap.ui.layout.BlockLayout/sample/sap.ui.layout.sample.BlockLayoutCustomBackgroundPerCell (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_343 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " the controller's _modelData: one record per cell, each bound as the
    " cell's own context (binding="{/cellN}") so the two Selects inside the
    " cell write straight into it
    TYPES:
      BEGIN OF ty_s_cell,
        colorset   TYPE string,
        colorshade TYPE string,
      END OF ty_s_cell.
    DATA cell1 TYPE ty_s_cell.
    DATA cell2 TYPE ty_s_cell.
    DATA cell3 TYPE ty_s_cell.
    DATA cell4 TYPE ty_s_cell.
    DATA cell5 TYPE ty_s_cell.
    DATA cell6 TYPE ty_s_cell.

  PROTECTED SECTION.
    " one entry of the fragment's shade Select
    TYPES:
      BEGIN OF ty_s_shade,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_shade.
    TYPES ty_t_shade TYPE STANDARD TABLE OF ty_s_shade WITH DEFAULT KEY.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS color_select IMPORTING cell TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_343 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA layout TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA custom_color TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA row2 TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA an_icon TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA simple_form TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA right_aligned TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA left_aligned TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA default_aligned TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    " the sample's six BlockLayoutRows, one statement per cell. Each bound cell
    " carries its OWN context (binding="{/cellN}") and hands itself to
    " color_select( ), which inlines the ColorSelect fragment - abap2UI5 serves
    " one view, so a core:Fragment reference has no file to resolve; the
    " relative {COLORSET}/{COLORSHADE} bindings then resolve against the cell's
    " context exactly like in the original.
    " resources/sample.css is injected through a core:HTML <style> (CSS braces
    " escaped \{ \} so the XMLView parser does not read them as bindings).
    
    layout = view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:f`    v = `sap.ui.layout.form`

        )->tag( n = `HTML` ns = `core`
            )->a( n = `content` v = `<style>.customCellImageBackground\{color:#fff;` &&
                                    `background-image:url("https://sdk.openui5.org/test-resources/sap/ui/layout/demokit/sample/BlockLayoutCustomBackgroundPerCell/resources/Night_sky.jpg");` &&
                                    `background-size:100% auto;background-position:0 80%\}` &&
                                    `.customCellImageBackground .sapUiBlockCellContent,` &&
                                    `.customCellImageBackground .sapUiBlockCellContent .sapMText\{color:#fff\}</style>`

        )->ele( n = `BlockLayout` ns = `l`
            )->a( n = `id` v = `blockLayout` ).

    " row 1: the colour picker alone
    
    custom_color = layout->ele( n = `BlockLayoutRow` ns = `l`
        )->ele( n = `BlockLayoutCell` ns = `l`
            )->a( n = `id`                   v = `cell-1`
            )->a( n = `binding`              v = |\{{ client->_bind_path( cell1 ) }\}|
            )->a( n = `title`                v = `Select Cells' Custom Color`
            )->a( n = `backgroundColorSet`   v = `{COLORSET}`
            )->a( n = `backgroundColorShade` v = `{COLORSHADE}` ).

    color_select( custom_color ).

    " row 2: the image cell (the one cell without a picker), then the icon cell
    
    row2 = layout->ele( n = `BlockLayoutRow` ns = `l` ).

    row2->ele( n = `BlockLayoutCell` ns = `l`
        )->a( n = `title`          v = `The Title`
        )->a( n = `titleAlignment` v = `Center`
        )->a( n = `class`          v = `customCellImageBackground`

        )->tag( `Text`
            )->a( n = `text` v = `Donec bibendum diam nibh, sit amet ornare ante fermentum sed. Ut vulputate justo at orci sollicitudin.` ).

    
    an_icon = row2->ele( n = `BlockLayoutCell` ns = `l`
        )->a( n = `id`                   v = `cell-2`
        )->a( n = `binding`              v = |\{{ client->_bind_path( cell2 ) }\}|
        )->a( n = `title`                v = `An Icon`
        )->a( n = `backgroundColorSet`   v = `{COLORSET}`
        )->a( n = `backgroundColorShade` v = `{COLORSHADE}` ).

    color_select( an_icon ).

    an_icon->tag( n = `Icon` ns = `core`
        )->a( n = `src` v = `sap-icon://add-activity` ).

    " row 3: picker and form share one VBox
    
    simple_form = layout->ele( n = `BlockLayoutRow` ns = `l`
        )->ele( n = `BlockLayoutCell` ns = `l`
            )->a( n = `id`                   v = `cell-3`
            )->a( n = `binding`              v = |\{{ client->_bind_path( cell3 ) }\}|
            )->a( n = `title`                v = `Simple Form`
            )->a( n = `backgroundColorSet`   v = `{COLORSET}`
            )->a( n = `backgroundColorShade` v = `{COLORSHADE}`

            )->ele( `VBox` ).

    color_select( simple_form ).

    simple_form->ele( n = `SimpleForm` ns = `f`
        )->a( n = `editable`         v = `true`
        )->a( n = `backgroundDesign` v = `Transparent`
        )->a( n = `layout`           v = `ResponsiveGridLayout`

        )->tag( `Label`
            )->a( n = `text` v = `sap.m.Input`
        )->tag( `Input`
            )->a( n = `type`        v = `Text`
            )->a( n = `placeholder` v = `Enter Name ...`
        )->tag( `Label`
            )->a( n = `text` v = `sap.m.TextArea`
        )->tag( `TextArea`
            )->a( n = `placeholder` v = `Please add your comment...`
            )->a( n = `rows`        v = `6`
            )->a( n = `maxLength`   v = `255`
            )->a( n = `width`       v = `100%`
        )->tag( `Label`
            )->a( n = `text` v = `sap.m.Text`
        )->tag( `Text`
            )->a( n = `text` v = `Donec bibendum diam nibh, sit amet ornare ante fermentum sed. Ut vulputate justo at orci sollicitudin, in gravida lectus aliquam. Vivamus tortor lorem, semper et diam ac, faucibus suscipit metus. ` &&
                                 `Curabitur eget aliquet purus, id vestibulum sapien. Cras vitae imperdiet felis. Fusce placerat velit orci, at tempor nisl aliquam laoreet. Aliquam in sapien sit amet tortor laoreet feugiat id ` &&
                                 `in ligula.` ).

    " rows 4-6: the three title alignments, each over the same text
    
    right_aligned = layout->ele( n = `BlockLayoutRow` ns = `l`
        )->ele( n = `BlockLayoutCell` ns = `l`
            )->a( n = `id`                   v = `cell-4`
            )->a( n = `binding`              v = |\{{ client->_bind_path( cell4 ) }\}|
            )->a( n = `title`                v = `Right Aligned Title`
            )->a( n = `titleAlignment`       v = `Right`
            )->a( n = `backgroundColorSet`   v = `{COLORSET}`
            )->a( n = `backgroundColorShade` v = `{COLORSHADE}` ).

    color_select( right_aligned ).

    right_aligned->tag( `Text`
        )->a( n = `text` v = `Morbi id ullamcorper lorem, vestibulum facilisis velit. Ut elementum aliquam nisl a pretium. Donec auctor mattis convallis. Aenean sodales tortor nec facilisis fringilla. Nam feugiat nulla at diam ` &&
                             `sollicitudin pretium. Sed at lacus volutpat, finibus arcu ultricies, convallis elit. Aliquam sollicitudin tortor sit amet mi consequat fringilla. Fusce nisl leo, tempor et nulla id, pellentesque ` &&
                             `suscipit augue. Morbi cursus molestie tellus. Ut volutpat orci interdum, condimentum risus sed, iaculis tellus. Proin nisi eros, tristique nec tortor quis, suscipit sodales dui.` ).

    
    left_aligned = layout->ele( n = `BlockLayoutRow` ns = `l`
        )->ele( n = `BlockLayoutCell` ns = `l`
            )->a( n = `id`                   v = `cell-5`
            )->a( n = `binding`              v = |\{{ client->_bind_path( cell5 ) }\}|
            )->a( n = `title`                v = `Left Aligned Title`
            )->a( n = `titleAlignment`       v = `Left`
            )->a( n = `backgroundColorSet`   v = `{COLORSET}`
            )->a( n = `backgroundColorShade` v = `{COLORSHADE}` ).

    color_select( left_aligned ).

    left_aligned->tag( `Text`
        )->a( n = `text` v = `Morbi id ullamcorper lorem, vestibulum facilisis velit. Ut elementum aliquam nisl a pretium. Donec auctor mattis convallis. Aenean sodales tortor nec facilisis fringilla. Nam feugiat nulla at diam ` &&
                             `sollicitudin pretium. Sed at lacus volutpat, finibus arcu ultricies, convallis elit. Aliquam sollicitudin tortor sit amet mi consequat fringilla. Fusce nisl leo, tempor et nulla id, pellentesque ` &&
                             `suscipit augue. Morbi cursus molestie tellus. Ut volutpat orci interdum, condimentum risus sed, iaculis tellus. Proin nisi eros, tristique nec tortor quis, suscipit sodales dui.` ).

    
    default_aligned = layout->ele( n = `BlockLayoutRow` ns = `l`
        )->ele( n = `BlockLayoutCell` ns = `l`
            )->a( n = `id`                   v = `cell-6`
            )->a( n = `binding`              v = |\{{ client->_bind_path( cell6 ) }\}|
            )->a( n = `title`                v = `Default Aligned Title`
            )->a( n = `backgroundColorSet`   v = `{COLORSET}`
            )->a( n = `backgroundColorShade` v = `{COLORSHADE}` ).

    color_select( default_aligned ).

    default_aligned->tag( `Text`
        )->a( n = `text` v = `Morbi id ullamcorper lorem, vestibulum facilisis velit. Ut elementum aliquam nisl a pretium. Donec auctor mattis convallis. Aenean sodales tortor nec facilisis fringilla. Nam feugiat nulla at diam ` &&
                             `sollicitudin pretium. Sed at lacus volutpat, finibus arcu ultricies, convallis elit. Aliquam sollicitudin tortor sit amet mi consequat fringilla. Fusce nisl leo, tempor et nulla id, pellentesque ` &&
                             `suscipit augue. Morbi cursus molestie tellus. Ut volutpat orci interdum, condimentum risus sed, iaculis tellus. Proin nisi eros, tristique nec tortor quis, suscipit sodales dui.` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD color_select.

    " the ColorSelect fragment, inlined into the cell it is given (the original
    " references it from six cells): a VBox with the two Labels and the two
    " Selects. The eleven ColorSets are numbered, the last one carrying a theme
    " note in its text; the six shades A..F likewise, on the last two
    DATA vbox TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA colorset TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp1 TYPE string.
    DATA colorshade TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp2 TYPE ty_t_shade.
    DATA temp3 LIKE LINE OF temp2.
    DATA t_shades LIKE temp2.
    DATA shade LIKE LINE OF t_shades.
    vbox = cell->ele( `VBox` ).

    
    colorset = vbox->tag( `Label`
        )->a( n = `text` v = `Cell Color Set`
        )->ele( `Select`
            )->a( n = `selectedKey` v = `{COLORSET}` ).

    DO 11 TIMES.
      
      IF sy-index = 11.
        temp1 = `ColorSet11 (transparent in SAP Horizon theme)`.
      ELSE.
        temp1 = |ColorSet{ sy-index }|.
      ENDIF.
      colorset->tag( n = `Item` ns = `core`
          )->a( n = `key`  v = |ColorSet{ sy-index }|
          )->a( n = `text` v = temp1 ).
    ENDDO.

    
    colorshade = vbox->tag( `Label`
        )->a( n = `text` v = `Cell Color Shade`
        )->ele( `Select`
            )->a( n = `selectedKey` v = `{COLORSHADE}` ).

    
    CLEAR temp2.
    
    temp3-key = `ShadeA`.
    temp3-text = `ShadeA`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `ShadeB`.
    temp3-text = `ShadeB`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `ShadeC`.
    temp3-text = `ShadeC`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `ShadeD`.
    temp3-text = `ShadeD`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `ShadeE`.
    temp3-text = `ShadeE (only available for SAP Quartz and Horizon themes)`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `ShadeF`.
    temp3-text = `ShadeF (only available for SAP Quartz and Horizon themes)`.
    INSERT temp3 INTO TABLE temp2.
    
    t_shades = temp2.

    
    LOOP AT t_shades INTO shade.
      colorshade->tag( n = `Item` ns = `core`
          )->a( n = `key`  v = shade-key
          )->a( n = `text` v = shade-text ).
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    " the controller's _modelData verbatim - every cell starts on ColorSet6,
    " with shades A..F one per cell
    CLEAR cell1.
    cell1-colorset = `ColorSet6`.
    cell1-colorshade = `ShadeA`.
    CLEAR cell2.
    cell2-colorset = `ColorSet6`.
    cell2-colorshade = `ShadeB`.
    CLEAR cell3.
    cell3-colorset = `ColorSet6`.
    cell3-colorshade = `ShadeC`.
    CLEAR cell4.
    cell4-colorset = `ColorSet6`.
    cell4-colorshade = `ShadeD`.
    CLEAR cell5.
    cell5-colorset = `ColorSet6`.
    cell5-colorshade = `ShadeE`.
    CLEAR cell6.
    cell6-colorset = `ColorSet6`.
    cell6-colorshade = `ShadeF`.

  ENDMETHOD.

ENDCLASS.
