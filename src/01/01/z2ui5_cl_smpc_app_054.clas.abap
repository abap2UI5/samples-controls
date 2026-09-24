" @keywords tree sap.m displays data hierarchical structure standardtreeitem
" @summary Tree displays data in hierarchical structure.
" @origin sap.m.sample.Tree - https://sdk.openui5.org/entity/sap.m.Tree/sample/sap.m.sample.Tree (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_054 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " one structure per nesting depth (ABAP has no recursive types) - the number is the depth in Tree.json, 1 = a root node
    TYPES:
      BEGIN OF ty_s_leaf,
        text TYPE string,
        ref  TYPE string,
      END OF ty_s_leaf,
      BEGIN OF ty_s_great_grandchild,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE STANDARD TABLE OF ty_s_leaf WITH DEFAULT KEY,
      END OF ty_s_great_grandchild,
      BEGIN OF ty_s_grandchild,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE STANDARD TABLE OF ty_s_great_grandchild WITH DEFAULT KEY,
      END OF ty_s_grandchild,
      BEGIN OF ty_s_child,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE STANDARD TABLE OF ty_s_grandchild WITH DEFAULT KEY,
      END OF ty_s_child,
      BEGIN OF ty_s_root,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE STANDARD TABLE OF ty_s_child WITH DEFAULT KEY,
      END OF ty_s_root.
    DATA t_nodes TYPE STANDARD TABLE OF ty_s_root WITH DEFAULT KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_054 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`

        )->ele( `Tree`
            )->a( n = `id`    v = `Tree`
            " '{path: '/'}' -> bind the root table; the nested `nodes` drive the depth
            )->a( n = `items` v = client->_bind( t_nodes )

            )->tag( `StandardTreeItem`
                )->a( n = `title` v = `{TEXT}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    DATA temp1 LIKE t_nodes.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp3 TYPE z2ui5_cl_smpc_app_054=>ty_s_root-nodes.
    DATA temp4 LIKE LINE OF temp3.
    DATA temp5 TYPE z2ui5_cl_smpc_app_054=>ty_s_child-nodes.
    DATA temp6 LIKE LINE OF temp5.
    DATA temp7 TYPE z2ui5_cl_smpc_app_054=>ty_s_grandchild-nodes.
    DATA temp8 LIKE LINE OF temp7.
    DATA temp9 TYPE z2ui5_cl_smpc_app_054=>ty_s_great_grandchild-nodes.
    DATA temp10 LIKE LINE OF temp9.
    CLEAR temp1.
    
    temp2-text = `Node1`.
    temp2-ref = `sap-icon://attachment-audio`.
    
    CLEAR temp3.
    
    temp4-text = `Node1-1`.
    temp4-ref = `sap-icon://attachment-e-pub`.
    
    CLEAR temp5.
    
    temp6-text = `Node1-1-1`.
    temp6-ref = `sap-icon://attachment-html`.
    INSERT temp6 INTO TABLE temp5.
    temp6-text = `Node1-1-2`.
    temp6-ref = `sap-icon://attachment-photo`.
    
    CLEAR temp7.
    
    temp8-text = `Node1-1-2-1`.
    temp8-ref = `sap-icon://attachment-text-file`.
    
    CLEAR temp9.
    
    temp10-text = `Node1-1-2-1-1`.
    temp10-ref = `sap-icon://attachment-video`.
    INSERT temp10 INTO TABLE temp9.
    temp10-text = `Node1-1-2-1-2`.
    temp10-ref = `sap-icon://attachment-zip-file`.
    INSERT temp10 INTO TABLE temp9.
    temp10-text = `Node1-1-2-1-3`.
    temp10-ref = `sap-icon://course-program`.
    INSERT temp10 INTO TABLE temp9.
    temp8-nodes = temp9.
    INSERT temp8 INTO TABLE temp7.
    temp6-nodes = temp7.
    INSERT temp6 INTO TABLE temp5.
    temp4-nodes = temp5.
    INSERT temp4 INTO TABLE temp3.
    temp4-text = `Node1-2`.
    temp4-ref = `sap-icon://create`.
    INSERT temp4 INTO TABLE temp3.
    temp2-nodes = temp3.
    INSERT temp2 INTO TABLE temp1.
    temp2-text = `Node2`.
    temp2-ref = `sap-icon://customer-financial-fact-sheet`.
    INSERT temp2 INTO TABLE temp1.
    t_nodes = temp1.

  ENDMETHOD.

ENDCLASS.
