" @keywords combobox combo box sap.m comboboxvalidation verticallayout label item
" @summary The combo box control could be restricted to allow selection only from the items in the list.
" @origin sap.m.sample.ComboBoxValidation - https://sdk.openui5.org/entity/sap.m.ComboBox/sample/sap.m.sample.ComboBoxValidation (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_475 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_country,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_country.
    TYPES ty_t_country TYPE STANDARD TABLE OF ty_s_country WITH DEFAULT KEY.

    DATA t_countries TYPE ty_t_country.

    DATA selected_key     TYPE string.
    DATA value            TYPE string.
    DATA value_state      TYPE string VALUE `None`.
    DATA value_state_text TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_475 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `Choose a country:`
                )->a( n = `labelFor` v = `idComboBox`
            " handleChange validates in the controller - validation is business logic,
            " so it happens in ABAP and the two value-state properties are bound
            )->ele( `ComboBox`
                )->a( n = `id`             v = `idComboBox`
                )->a( n = `items`          v = |\{ path: '{ client->_bind_path( t_countries ) }', sorter: \{ path: 'TEXT' \} \}|
                )->a( n = `selectedKey`    v = client->_bind( selected_key )
                )->a( n = `value`          v = client->_bind( value )
                )->a( n = `valueState`     v = client->_bind( value_state )
                )->a( n = `valueStateText` v = client->_bind( value_state_text )
                )->a( n = `change`         v = client->_event( `CHANGE` )

                )->tag( n = `Item` ns = `core`
                    )->a( n = `text` v = `{TEXT}`
                    )->a( n = `key`  v = `{KEY}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp1 TYPE string.

    IF client->get_event( ) = `CHANGE`.

      " a typed value with no matching key is the error case of the original
      IF selected_key IS INITIAL AND value IS NOT INITIAL.
        value_state      = `Error`.
        value_state_text = `Please enter a valid country!`.
      ELSE.
        value_state      = `None`.
        
        CLEAR temp1.
        value_state_text = temp1.
      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " full mock /CountriesCollection of ui5/mock/countriesExtendedCollection.json
    DATA temp2 TYPE z2ui5_cl_smpc_app_475=>ty_t_country.
    DATA temp3 LIKE LINE OF temp2.
    CLEAR temp2.
    
    temp3-key = `DZ`.
    temp3-text = `Algeria`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `AR`.
    temp3-text = `Argentina`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `AU`.
    temp3-text = `Australia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `AT`.
    temp3-text = `Austria`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `BH`.
    temp3-text = `Bahrain`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `BE`.
    temp3-text = `Belgium`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `BA`.
    temp3-text = `Bosnia and Herzegovina`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `BR`.
    temp3-text = `Brazil`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `BG`.
    temp3-text = `Bulgaria`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `CA`.
    temp3-text = `Canada`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `CL`.
    temp3-text = `Chile`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `CO`.
    temp3-text = `Colombia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `HR`.
    temp3-text = `Croatia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `CU`.
    temp3-text = `Cuba`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `CZ`.
    temp3-text = `Czech Republic`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `DK`.
    temp3-text = `Denmark`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `EG`.
    temp3-text = `Egypt`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `EE`.
    temp3-text = `Estonia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `FI`.
    temp3-text = `Finland`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `FR`.
    temp3-text = `France`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `GER`.
    temp3-text = `Germany`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `GH`.
    temp3-text = `Ghana`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `GR`.
    temp3-text = `Greece`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `HU`.
    temp3-text = `Hungary`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `IN`.
    temp3-text = `India`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `ID`.
    temp3-text = `Indonesia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `IE`.
    temp3-text = `Ireland`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `IL`.
    temp3-text = `Israel`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `IT`.
    temp3-text = `Italy`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `JP`.
    temp3-text = `Japan`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `JO`.
    temp3-text = `Jordan`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `KE`.
    temp3-text = `Kenya`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `KW`.
    temp3-text = `Kuwait`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `LV`.
    temp3-text = `Latvia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `LT`.
    temp3-text = `Lithuania`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `MK`.
    temp3-text = `Macedonia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `MY`.
    temp3-text = `Malaysia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `MX`.
    temp3-text = `Mexico`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `ME`.
    temp3-text = `Montenegro`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `MA`.
    temp3-text = `Morocco`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `NL`.
    temp3-text = `Netherlands`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `NZ`.
    temp3-text = `New Zealand`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `NG`.
    temp3-text = `Nigeria`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `NO`.
    temp3-text = `Norway`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `OM`.
    temp3-text = `Oman`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `PE`.
    temp3-text = `Peru`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `PH`.
    temp3-text = `Philippines`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `PL`.
    temp3-text = `Poland`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `PT`.
    temp3-text = `Portugal`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `QA`.
    temp3-text = `Qatar`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `RO`.
    temp3-text = `Romania`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `RU`.
    temp3-text = `Russia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `SA`.
    temp3-text = `Saudi Arabia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `SN`.
    temp3-text = `Senegal`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `RS`.
    temp3-text = `Serbia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `SG`.
    temp3-text = `Singapore`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `SK`.
    temp3-text = `Slovakia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `SI`.
    temp3-text = `Slovenia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `ZA`.
    temp3-text = `South Africa`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `KR`.
    temp3-text = `South Korea`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `ES`.
    temp3-text = `Spain`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `SE`.
    temp3-text = `Sweden`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `CH`.
    temp3-text = `Switzerland`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `TN`.
    temp3-text = `Tunisia`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `TR`.
    temp3-text = `Turkey`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `UG`.
    temp3-text = `Uganda`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `UA`.
    temp3-text = `Ukraine`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `AE`.
    temp3-text = `United Arab Emirates`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `GB`.
    temp3-text = `United Kingdom`.
    INSERT temp3 INTO TABLE temp2.
    temp3-key = `YE`.
    temp3-text = `Yemen`.
    INSERT temp3 INTO TABLE temp2.
    t_countries = temp2.

  ENDMETHOD.

ENDCLASS.
