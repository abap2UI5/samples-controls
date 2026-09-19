" @keywords gridlist grid list sap.f gridboxlayout slider panel toolbar title gridlistitem vbox flexitemdata
" @summary This layout allows to display same height grid items with configurable width.
" @origin sap.f.sample.GridListBoxContainer - https://sdk.openui5.org/entity/sap.f.GridList/sample/sap.f.sample.GridListBoxContainer (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_144 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_item,
        title    TYPE string,
        subtitle TYPE string,
      END OF ty_item.
    DATA t_items      TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.
    DATA slider_value TYPE i.
    DATA panel_width  TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_144 IMPLEMENTATION.

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
    DATA temp1 TYPE z2ui5_if_client=>ty_s_event_control.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    temp1-check_queue_last = abap_true.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:grid` v = `sap.ui.layout.cssgrid`
        )->a( n = `xmlns:f`    v = `sap.f`

        )->tag( `Slider`
            )->a( n = `value`      v = client->_bind( slider_value )
            )->a( n = `liveChange` v = client->_event( val = `SLIDER` s_ctrl = temp1 )

        )->ele( `Panel`
            )->a( n = `id`               v = `panelForGridList`
            )->a( n = `backgroundDesign` v = `Transparent`
            )->a( n = `width`            v = client->_bind( panel_width )

            )->ele( `headerToolbar`
                )->ele( `Toolbar`
                    )->a( n = `height` v = `3rem`
                    )->tag( `Title`
                        )->a( n = `text` v = `Grid List with GridBoxLayout and minWidth 17rem`

                )->end(
            )->end(

            )->ele( n = `GridList` ns = `f`
                )->a( n = `id`         v = `gridList`
                )->a( n = `headerText` v = `GridList header`
                )->a( n = `items`      v = client->_bind( t_items )

                )->ele( n = `customLayout` ns = `f`
                    )->tag( n = `GridBoxLayout` ns = `grid`
                        )->a( n = `boxMinWidth` v = `17rem`

                )->end(

                )->ele( n = `GridListItem` ns = `f`
                    )->ele( `VBox`
                        )->a( n = `class` v = `sapUiSmallMargin`
                        )->ele( `layoutData`
                            )->tag( `FlexItemData`
                                )->a( n = `growFactor`   v = `1`
                                )->a( n = `shrinkFactor` v = `0`

                        )->end(
                        )->tag( `Title`
                            )->a( n = `text`     v = `{TITLE}`
                            )->a( n = `wrapping` v = `true`
                        )->tag( `Label`
                            )->a( n = `text`     v = `{SUBTITLE}`
                            )->a( n = `wrapping` v = `true` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `SLIDER`.
      " original onSliderMoved: byId('panelForGridList').setWidth(value + '%')
      panel_width = |{ slider_value }%|.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.
    DATA temp2 LIKE t_items.
    DATA temp3 LIKE LINE OF temp2.

    slider_value = 100.
    panel_width  = `100%`.
    
    CLEAR temp2.
    
    temp3-title = `Grid item title 1`.
    temp3-subtitle = `Subtitle 1`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 2`.
    temp3-subtitle = `Subtitle 2`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 3`.
    temp3-subtitle = `Subtitle 3`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 4`.
    temp3-subtitle = `Subtitle 4`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 5`.
    temp3-subtitle = `Subtitle 5`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 6 Grid item title Grid item title Grid item title Grid item title Grid item title`.
    temp3-subtitle = `Subtitle 6`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Very long Grid item title that should wrap 7`.
    temp3-subtitle = `This is a long subtitle 7`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 8`.
    temp3-subtitle = `Subtitle 8`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 9 Grid item title B  Grid item title B 9 Grid item title B 9Grid item title B 9title B 9 Grid item title B 9Grid item title B`.
    temp3-subtitle = `Subtitle 9`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 10`.
    temp3-subtitle = `Subtitle 10`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 11`.
    temp3-subtitle = `Subtitle 11`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 12`.
    temp3-subtitle = `Subtitle 12`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 13`.
    temp3-subtitle = `Subtitle 13`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 14`.
    temp3-subtitle = `Subtitle 14`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 15`.
    temp3-subtitle = `Subtitle 15`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 16`.
    temp3-subtitle = `Subtitle 16`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 17`.
    temp3-subtitle = `Subtitle 17`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title 18`.
    temp3-subtitle = `Subtitle 18`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Very long Grid item title that should wrap 19`.
    temp3-subtitle = `This is a long subtitle 19`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 20`.
    temp3-subtitle = `Subtitle 20`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 21`.
    temp3-subtitle = `Subtitle 21`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 22`.
    temp3-subtitle = `Subtitle 22`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 23`.
    temp3-subtitle = `Subtitle 23`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 24`.
    temp3-subtitle = `Subtitle 24`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 21`.
    temp3-subtitle = `Subtitle 21`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 22`.
    temp3-subtitle = `Subtitle 22`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Grid item title B 23`.
    temp3-subtitle = `Subtitle 23`.
    INSERT temp3 INTO TABLE temp2.
    t_items = temp2.

  ENDMETHOD.

ENDCLASS.
