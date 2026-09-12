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
        nodes TYPE STANDARD TABLE OF ty_s_leaf WITH EMPTY KEY,
      END OF ty_s_great_grandchild,
      BEGIN OF ty_s_grandchild,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE STANDARD TABLE OF ty_s_great_grandchild WITH EMPTY KEY,
      END OF ty_s_grandchild,
      BEGIN OF ty_s_child,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE STANDARD TABLE OF ty_s_grandchild WITH EMPTY KEY,
      END OF ty_s_child,
      BEGIN OF ty_s_root,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE STANDARD TABLE OF ty_s_child WITH EMPTY KEY,
      END OF ty_s_root.
    DATA t_nodes TYPE STANDARD TABLE OF ty_s_root WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_054 IMPLEMENTATION.

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

    t_nodes = VALUE #(
        ( text  = `Node1`
          ref   = `sap-icon://attachment-audio`
          nodes = VALUE #(
              ( text  = `Node1-1`
                ref   = `sap-icon://attachment-e-pub`
                nodes = VALUE #(
                    ( text = `Node1-1-1`
                      ref  = `sap-icon://attachment-html` )
                    ( text  = `Node1-1-2`
                      ref   = `sap-icon://attachment-photo`
                      nodes = VALUE #(
                          ( text  = `Node1-1-2-1`
                            ref   = `sap-icon://attachment-text-file`
                            nodes = VALUE #(
                                ( text = `Node1-1-2-1-1`
                                  ref  = `sap-icon://attachment-video` )
                                ( text = `Node1-1-2-1-2`
                                  ref  = `sap-icon://attachment-zip-file` )
                                ( text = `Node1-1-2-1-3`
                                  ref  = `sap-icon://course-program` ) ) ) ) ) ) )
              ( text = `Node1-2`
                ref  = `sap-icon://create` ) ) )
        ( text = `Node2`
          ref  = `sap-icon://customer-financial-fact-sheet` ) ).

  ENDMETHOD.

ENDCLASS.
