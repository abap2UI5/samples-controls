" @keywords customtreeitem custom tree item sap.m flexbox button input flexitemdata
" @summary With the Custom Tree Item you can add any kind of content to Tree.
" @origin sap.m.sample.CustomTreeItem - https://sdk.openui5.org/entity/sap.m.CustomTreeItem/sample/sap.m.sample.CustomTreeItem (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_015 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " one structure per nesting depth (ABAP has no recursive types) - the number is the depth in Tree.json, 1 = a root node
    TYPES:
      BEGIN OF ty_s_leaf,
        text TYPE string,
        ref  TYPE string,
      END OF ty_s_leaf.
    TYPES ty_t_leaf TYPE STANDARD TABLE OF ty_s_leaf WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_great_grandchild,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE ty_t_leaf,
      END OF ty_s_great_grandchild.
    TYPES ty_t_great_grandchild TYPE STANDARD TABLE OF ty_s_great_grandchild WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_grandchild,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE ty_t_great_grandchild,
      END OF ty_s_grandchild.
    TYPES ty_t_grandchild TYPE STANDARD TABLE OF ty_s_grandchild WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_child,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE ty_t_grandchild,
      END OF ty_s_child.
    TYPES ty_t_child TYPE STANDARD TABLE OF ty_s_child WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_root,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE ty_t_child,
      END OF ty_s_root.
    DATA t_tree TYPE STANDARD TABLE OF ty_s_root WITH DEFAULT KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_015 IMPLEMENTATION.

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
    DATA temp1 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `MESSAGE_TOAST` INTO TABLE temp1.
    INSERT `show` INTO TABLE temp1.
    INSERT `Button pressed` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `Tree`
            )->a( n = `id`    v = `Tree`
            )->a( n = `items` v = |\{ path: '{ client->_bind_path( t_tree ) }' \}|
            )->a( n = `mode`  v = `MultiSelect`

            )->ele( `CustomTreeItem`
                )->ele( `FlexBox`
                    )->a( n = `alignItems` v = `Start`
                    )->a( n = `width`      v = `100%`

                    )->ele( `items`
                        )->tag( `Button`
                            )->a( n = `icon`  v = `{REF}`
                            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                            t_arg = temp1 )
                            )->a( n = `class` v = `sapUiSmallMarginEnd`

                        )->ele( `Input`
                            )->a( n = `value` v = `{TEXT}`

                            )->ele( `layoutData`
                                )->tag( `FlexItemData`
                                    )->a( n = `growFactor` v = `1` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    DATA temp3 LIKE t_tree.
    DATA temp4 LIKE LINE OF temp3.
    DATA temp1 TYPE z2ui5_cl_smpc_app_015=>ty_t_child.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp5 TYPE z2ui5_cl_smpc_app_015=>ty_t_grandchild.
    DATA temp6 LIKE LINE OF temp5.
    DATA temp7 TYPE z2ui5_cl_smpc_app_015=>ty_t_great_grandchild.
    DATA temp8 LIKE LINE OF temp7.
    DATA temp9 TYPE z2ui5_cl_smpc_app_015=>ty_t_leaf.
    DATA temp10 LIKE LINE OF temp9.
    CLEAR temp3.
    
    temp4-text = `Node1`.
    temp4-ref = `sap-icon://attachment-audio`.
    
    CLEAR temp1.
    
    temp2-text = `Node1-1`.
    temp2-ref = `sap-icon://attachment-e-pub`.
    
    CLEAR temp5.
    
    temp6-text = `Node1-1-1`.
    temp6-ref = `sap-icon://attachment-html`.
    INSERT temp6 INTO TABLE temp5.
    temp6-text = `Node1-1-2`.
    temp6-ref = `sap-icon://attachment-photo`.
    
    CLEAR temp7.
    
    temp8-text = `Node1-1-1`.
    temp8-ref = `sap-icon://attachment-text-file`.
    
    CLEAR temp9.
    
    temp10-text = `Node1-1-1-1`.
    temp10-ref = `sap-icon://attachment-video`.
    INSERT temp10 INTO TABLE temp9.
    temp10-text = `Node1-1-1-2`.
    temp10-ref = `sap-icon://attachment-zip-file`.
    INSERT temp10 INTO TABLE temp9.
    temp10-text = `Node1-1-1-3`.
    temp10-ref = `sap-icon://course-program`.
    INSERT temp10 INTO TABLE temp9.
    temp8-nodes = temp9.
    INSERT temp8 INTO TABLE temp7.
    temp6-nodes = temp7.
    INSERT temp6 INTO TABLE temp5.
    temp2-nodes = temp5.
    INSERT temp2 INTO TABLE temp1.
    temp2-text = `Node1-2`.
    temp2-ref = `sap-icon://create`.
    INSERT temp2 INTO TABLE temp1.
    temp4-nodes = temp1.
    INSERT temp4 INTO TABLE temp3.
    temp4-text = `Node2`.
    temp4-ref = `sap-icon://customer-financial-fact-sheet`.
    INSERT temp4 INTO TABLE temp3.
    t_tree = temp3.

  ENDMETHOD.

ENDCLASS.
