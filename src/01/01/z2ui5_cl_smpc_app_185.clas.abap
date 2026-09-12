" @keywords whitespacepattern whitespace pattern sap.m messagestrip link form responsivegridlayout formcontainer formelement input listitem
" @summary Renders whitespaces properly within controls
" @origin sap.m.sample.WhitespacePattern - https://sdk.openui5.org/entity/sap.m.WhitespacePattern/sample/sap.m.sample.WhitespacePattern (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_185 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_item,
        key            TYPE i,
        text           TYPE string,
        additionaltext TYPE string,
      END OF ty_item.
    DATA t_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_185 IMPLEMENTATION.

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

    " The default model is one array of rows; abap2UI5's single default model is
    " an object, so the sample's root-array bindings ({/}, /9/text) resolve
    " against the T_ITEMS member (last path segment identical). The original's
    " '.whitespace2Char' formatter is applied in model_init - see the sidecar.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`

        )->ele( `MessageStrip`
            )->a( n = `text`  v = `More information could be found on the following page:`
            )->a( n = `class` v = `sapUiMediumMargin`

            )->ele( `link`
                )->tag( `Link`
                    )->a( n = `text` v = `Whitespaces concept`
                    )->a( n = `href` v = `topic/37deb0bee3e2474887f1521cc583ab69`

            )->end(
        )->end(

        )->ele( n = `Form` ns = `form`
            )->a( n = `editable` v = `true`

            )->ele( n = `layout` ns = `form`
                )->tag( n = `ResponsiveGridLayout` ns = `form`
                    )->a( n = `labelSpanXL`             v = `4`
                    )->a( n = `labelSpanL`              v = `3`
                    )->a( n = `labelSpanM`              v = `4`
                    )->a( n = `labelSpanS`              v = `12`
                    )->a( n = `adjustLabelSpan`         v = `false`
                    )->a( n = `emptySpanXL`             v = `0`
                    )->a( n = `emptySpanL`              v = `4`
                    )->a( n = `emptySpanM`              v = `0`
                    )->a( n = `emptySpanS`              v = `0`
                    )->a( n = `columnsXL`               v = `2`
                    )->a( n = `columnsL`                v = `1`
                    )->a( n = `columnsM`                v = `1`
                    )->a( n = `singleContainerFullSize` v = `false`

            )->end(

            )->ele( n = `formContainers` ns = `form`
                )->ele( n = `FormContainer` ns = `form`
                    )->ele( n = `formElements` ns = `form`
                        )->ele( n = `FormElement` ns = `form`
                            )->a( n = `label` v = `sap.m.Input`

                            )->ele( n = `fields` ns = `form`
                                )->ele( `Input`
                                    )->a( n = `placeholder`     v = `Type 'Text'`
                                    )->a( n = `showSuggestion`  v = `true`
                                    )->a( n = `suggestionItems` v = client->_bind( t_items )

                                    )->ele( `suggestionItems`
                                        )->tag( n = `ListItem` ns = `core`
                                            )->a( n = `key`            v = `{KEY}`
                                            )->a( n = `text`           v = `{TEXT}`
                                            )->a( n = `additionalText` v = `{ADDITIONALTEXT}`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(

                        )->ele( n = `FormElement` ns = `form`
                            )->a( n = `label` v = `sap.m.MultiInput`

                            )->ele( n = `fields` ns = `form`
                                )->ele( `MultiInput`
                                    )->a( n = `placeholder`     v = `Type 'Text'`
                                    )->a( n = `showSuggestion`  v = `true`
                                    )->a( n = `suggestionItems` v = client->_bind( t_items )

                                    )->ele( `suggestionItems`
                                        )->tag( n = `ListItem` ns = `core`
                                            )->a( n = `key`            v = `{KEY}`
                                            )->a( n = `text`           v = `{TEXT}`
                                            )->a( n = `additionalText` v = `{ADDITIONALTEXT}`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(

                        )->ele( n = `FormElement` ns = `form`
                            )->a( n = `label` v = `sap.m.MultiComboBox`

                            )->ele( n = `fields` ns = `form`
                                )->ele( `MultiComboBox`
                                    )->a( n = `placeholder`         v = `Type 'Text'`
                                    )->a( n = `showSecondaryValues` v = `true`
                                    )->a( n = `items`               v = client->_bind( t_items )

                                    )->tag( n = `ListItem` ns = `core`
                                        )->a( n = `key`            v = `{KEY}`
                                        )->a( n = `text`           v = `{TEXT}`
                                        )->a( n = `additionalText` v = `{ADDITIONALTEXT}`

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end(

        )->ele( n = `Form` ns = `form`
            )->a( n = `editable` v = `false`

            )->ele( n = `layout` ns = `form`
                )->tag( n = `ResponsiveGridLayout` ns = `form`
                    )->a( n = `labelSpanXL`             v = `4`
                    )->a( n = `labelSpanL`              v = `3`
                    )->a( n = `labelSpanM`              v = `4`
                    )->a( n = `labelSpanS`              v = `12`
                    )->a( n = `adjustLabelSpan`         v = `false`
                    )->a( n = `emptySpanXL`             v = `0`
                    )->a( n = `emptySpanL`              v = `4`
                    )->a( n = `emptySpanM`              v = `0`
                    )->a( n = `emptySpanS`              v = `0`
                    )->a( n = `columnsXL`               v = `2`
                    )->a( n = `columnsL`                v = `1`
                    )->a( n = `columnsM`                v = `1`
                    )->a( n = `singleContainerFullSize` v = `false`

            )->end(

            )->ele( n = `formContainers` ns = `form`
                )->ele( n = `FormContainer` ns = `form`
                    )->ele( n = `formElements` ns = `form`
                        )->ele( n = `FormElement` ns = `form`
                            )->a( n = `label` v = `sap.m.Token`

                            )->ele( n = `fields` ns = `form`
                                )->tag( `Token`
                                    )->a( n = `text` v = |\{ path: '{ client->_bind_path( t_items ) }/9/TEXT' \}|
                                    )->a( n = `key`  v = |\{ path: '{ client->_bind_path( t_items ) }/9/KEY' \}|

                            )->end(
                        )->end(

                        )->ele( n = `FormElement` ns = `form`
                            )->a( n = `label` v = `sap.m.Text`

                            )->ele( n = `fields` ns = `form`
                                )->tag( `ObjectStatus`
                                    )->a( n = `text` v = |\{ path: '{ client->_bind_path( t_items ) }/9/TEXT' \}|

                            )->end(
                        )->end(

                        )->ele( n = `FormElement` ns = `form`
                            )->a( n = `label` v = `sap.m.ObjectNumber`

                            )->ele( n = `fields` ns = `form`
                                )->tag( `ObjectNumber`
                                    )->a( n = `number` v = |\{ path: '{ client->_bind_path( t_items ) }/9/TEXT' \}|

                            )->end(
                        )->end(

                        )->ele( n = `FormElement` ns = `form`
                            )->a( n = `label` v = `sap.m.Title`

                            )->ele( n = `fields` ns = `form`
                                )->tag( `Title`
                                    )->a( n = `text` v = |\{ path: '{ client->_bind_path( t_items ) }/9/TEXT' \}|

                            )->end(
                        )->end(

                        )->ele( n = `FormElement` ns = `form`
                            )->a( n = `label` v = `sap.m.Label`

                            )->ele( n = `fields` ns = `form`
                                )->tag( `Label`
                                    )->a( n = `text` v = |\{ path: '{ client->_bind_path( t_items ) }/9/TEXT' \}| ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " The original controller builds 10 rows ("Text with <n> whitespaces" /
    " "Additional text with <n> whitespaces") and a '.whitespace2Char' formatter
    " turns every doubled space into space + non-breaking space so consecutive
    " whitespaces stay visible. abap2UI5 is a thin frontend, so that
    " presentation transform is applied here in ABAP (identical output) and the
    " view binds the finished text.
    CONSTANTS nbsp TYPE string VALUE ` `.

    DATA(repl) = ` ` && nbsp.
    DATA inverted   TYPE i.
    DATA text       TYPE string.
    DATA additional TYPE string.

    DO 10 TIMES.
      DATA(i) = sy-index.
      inverted = 11 - i.

      text       = |Text with { repeat( val = ` ` occ = i - 1 ) }{ i } whitespaces|.
      additional = |Additional text with { repeat( val = ` ` occ = inverted - 1 ) }{ inverted } whitespaces|.

      REPLACE ALL OCCURRENCES OF `  ` IN text WITH repl.
      REPLACE ALL OCCURRENCES OF `  ` IN additional WITH repl.

      APPEND VALUE #( key = i text = text additionaltext = additional ) TO t_items.
    ENDDO.

  ENDMETHOD.

ENDCLASS.
