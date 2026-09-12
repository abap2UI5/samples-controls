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
    TYPES ty_t_leaf TYPE STANDARD TABLE OF ty_s_leaf WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_great_grandchild,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE ty_t_leaf,
      END OF ty_s_great_grandchild.
    TYPES ty_t_great_grandchild TYPE STANDARD TABLE OF ty_s_great_grandchild WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_grandchild,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE ty_t_great_grandchild,
      END OF ty_s_grandchild.
    TYPES ty_t_grandchild TYPE STANDARD TABLE OF ty_s_grandchild WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_child,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE ty_t_grandchild,
      END OF ty_s_child.
    TYPES ty_t_child TYPE STANDARD TABLE OF ty_s_child WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_root,
        text  TYPE string,
        ref   TYPE string,
        nodes TYPE ty_t_child,
      END OF ty_s_root.
    DATA t_tree TYPE STANDARD TABLE OF ty_s_root WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_015 IMPLEMENTATION.

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
                                                                            t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `Button pressed` ) ) )
                            )->a( n = `class` v = `sapUiSmallMarginEnd`

                        )->ele( `Input`
                            )->a( n = `value` v = `{TEXT}`

                            )->ele( `layoutData`
                                )->tag( `FlexItemData`
                                    )->a( n = `growFactor` v = `1` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    t_tree = VALUE #(
      ( text = `Node1` ref = `sap-icon://attachment-audio` nodes = VALUE #(
          ( text = `Node1-1` ref = `sap-icon://attachment-e-pub` nodes = VALUE #(
              ( text = `Node1-1-1` ref = `sap-icon://attachment-html` )
              ( text = `Node1-1-2` ref = `sap-icon://attachment-photo` nodes = VALUE #(
                  ( text = `Node1-1-1` ref = `sap-icon://attachment-text-file` nodes = VALUE #(
                      ( text = `Node1-1-1-1` ref = `sap-icon://attachment-video` )
                      ( text = `Node1-1-1-2` ref = `sap-icon://attachment-zip-file` )
                      ( text = `Node1-1-1-3` ref = `sap-icon://course-program` ) ) ) ) ) ) )
          ( text = `Node1-2`     ref = `sap-icon://create` ) ) )
      ( text = `Node2`       ref = `sap-icon://customer-financial-fact-sheet` ) ).

  ENDMETHOD.

ENDCLASS.
