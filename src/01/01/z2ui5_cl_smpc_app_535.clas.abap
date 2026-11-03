" @keywords wizard sap.m wizardbranching navcontainer wizardstep objectheader objectattribute list standardlistitem text hbox segmentedbutton
" @summary The Wizard could be used in branching mode, where the choice of next step depends on the decision made for the current one.
" @origin sap.m.sample.WizardBranching - https://sdk.openui5.org/entity/sap.m.Wizard/sample/sap.m.sample.WizardBranching (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_535 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        description   TYPE string,
        productpicurl TYPE string,
        price         TYPE p LENGTH 8 DECIMALS 2,
        currencycode  TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    DATA productcollection    TYPE ty_t_product.
    DATA productstotalprice   TYPE p LENGTH 8 DECIMALS 2.

    " The original keeps the form data in nested paths on one JSON model
    " (/CreditCard/Name, /CashOnDelivery/FirstName, /BillingAddress/Address ...).
    " abap2UI5 keeps one default model, so the nested paths are folded to flat
    " fields with the identical last segment (app 166 idiom)
    DATA selectedpayment        TYPE string.
    DATA selecteddeliverymethod TYPE string.
    DATA differentdeliveryaddress TYPE abap_bool.
    DATA name                   TYPE string.
    DATA cardnumber             TYPE string.
    DATA securitycode           TYPE string.
    DATA expire                 TYPE string.
    DATA firstname              TYPE string.
    DATA lastname               TYPE string.
    DATA phonenumber            TYPE string.
    DATA email                  TYPE string.
    DATA address                TYPE string.
    DATA city                   TYPE string.
    DATA zipcode                TYPE string.
    DATA country                TYPE string.
    DATA note                   TYPE string.

    DATA creditcard_validated TYPE abap_bool.
    DATA cod_validated        TYPE abap_bool.
    DATA billing_validated    TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    " getProgressStep() is not readable from a backend; the two flags below stand
    " in for the two comparisons setDiscardableProperty makes, and each is set by
    " the activate wire of the step that FOLLOWS the one being compared
    DATA payment_passed TYPE abap_bool.
    DATA billing_passed TYPE abap_bool.
    DATA prev_payment          TYPE string.
    DATA prev_diff_delivery    TYPE abap_bool.
    DATA pending_discard       TYPE string.

    METHODS view_display.
    METHODS on_event.
    METHODS branch_payment.
    METHODS branch_delivery.
    METHODS nav_back_to_step IMPORTING step_id TYPE string.
    METHODS total_calc.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_535 IMPLEMENTATION.

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
    DATA temp2 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp3 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp4 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp5 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp6 TYPE z2ui5_if_client=>ty_s_event_control.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    temp1-check_queue_last = abap_true.
    temp1-check_no_busy = abap_true.
    
    CLEAR temp2.
    temp2-check_queue_last = abap_true.
    temp2-check_no_busy = abap_true.
    
    CLEAR temp3.
    temp3-check_queue_last = abap_true.
    temp3-check_no_busy = abap_true.
    
    CLEAR temp4.
    temp4-check_queue_last = abap_true.
    temp4-check_no_busy = abap_true.
    
    CLEAR temp5.
    temp5-check_queue_last = abap_true.
    temp5-check_no_busy = abap_true.
    
    CLEAR temp6.
    temp6-check_queue_last = abap_true.
    temp6-check_no_busy = abap_true.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `NavContainer`
            )->a( n = `id` v = `wizardNavContainer`

            )->ele( `pages`
                )->ele( `Page`
                    )->a( n = `id`         v = `wizardContentPage`
                    )->a( n = `showHeader` v = `false`

                    )->ele( `content`
                        )->ele( `Wizard`
                            )->a( n = `id`              v = `ShoppingCartWizard`
                            )->a( n = `complete`        v = client->_event( `WIZARD_COMPLETE` )
                            )->a( n = `enableBranching` v = `true`
                            )->a( n = `class`           v = `sapUiResponsivePadding--header sapUiResponsivePadding--content`

                            )->ele( `WizardStep`
                                )->a( n = `id`       v = `ContentsStep`
                                )->a( n = `nextStep` v = `PaymentTypeStep`
                                )->a( n = `title`    v = `Shopping cart contents`
                                )->a( n = `icon`     v = `sap-icon://cart`

                                )->ele( `ObjectHeader`
                                    )->a( n = `title`      v = `Total`
                                    )->a( n = `number`     v = client->_bind( productstotalprice )
                                    )->a( n = `numberUnit` v = `EUR`

                                    )->ele( `attributes`
                                        )->tag( `ObjectAttribute`
                                            )->a( n = `text` v = `This is the list of items in your shopping cart`

                                    )->end(
                                )->end(
                                )->ele( `List`
                                    )->a( n = `mode`                v = `Delete`
                                    )->a( n = `items`               v = client->_bind( productcollection )
                                    )->a( n = `enableBusyIndicator` v = `true`
                                    )->a( n = `delete`              v = client->_event( val = `DELETE_ITEM` arg = `${$parameters>/listItem}.getTitle()` )
                                    )->a( n = `headerText`          v = `Items`

                                    )->tag( `StandardListItem`
                                        )->a( n = `title`            v = `{NAME}`
                                        )->a( n = `type`             v = `Active`
                                        )->a( n = `description`      v = `{DESCRIPTION}`
                                        )->a( n = `icon`             v = `{PRODUCTPICURL}`
                                        )->a( n = `info`             v = `{PRICE} {CURRENCYCODE}`
                                        )->a( n = `iconDensityAware` v = `false`
                                        )->a( n = `iconInset`        v = `false`

                                )->end(
                            )->end(

                            )->ele( `WizardStep`
                                )->a( n = `id`              v = `PaymentTypeStep`
                                )->a( n = `title`           v = `Payment type`
                                )->a( n = `nextStep`        v = `CreditCardStep`
                                )->a( n = `subsequentSteps` v = `CreditCardStep, BankAccountStep, CashOnDeliveryStep`
                                )->a( n = `complete`        v = client->_event( `GOTO_PAYMENT` )
                                )->a( n = `icon`            v = `sap-icon://money-bills`

                                )->tag( `Text`
                                    )->a( n = `class` v = `sapUiSmallMarginBottom`
                                    )->a( n = `text`  v = `We accept all major credit cards. No extra cost will be charged when paying with a credit card. Bank transfer and Cash on delivery are only ` &&
                                                          `possible for inland deliveries. A service charge of 2.99 EUR will be charged for these types of deliveries. Be aware, that for Bank transfers, ` &&
                                                          `the shipping will start on the day after the payment is received.`

                                )->ele( `HBox`
                                    )->a( n = `alignItems`     v = `Center`
                                    )->a( n = `justifyContent` v = `Center`
                                    )->a( n = `width`          v = `100%`

                                    )->ele( `SegmentedButton`
                                        )->a( n = `selectionChange` v = client->_event( `SET_PAYMENT` )
                                        )->a( n = `id`              v = `paymentMethodSelection`
                                        )->a( n = `selectedKey`     v = client->_bind( selectedpayment )

                                        )->ele( `items`
                                            )->tag( `SegmentedButtonItem`
                                                )->a( n = `key`  v = `Credit Card`
                                                )->a( n = `icon` v = `sap-icon://credit-card`
                                                )->a( n = `text` v = `Credit card`
                                            )->tag( `SegmentedButtonItem`
                                                )->a( n = `key`  v = `Bank Transfer`
                                                )->a( n = `icon` v = `sap-icon://official-service`
                                                )->a( n = `text` v = `Bank transfer`
                                            )->tag( `SegmentedButtonItem`
                                                )->a( n = `key`  v = `Cash on Delivery`
                                                )->a( n = `icon` v = `sap-icon://money-bills`
                                                )->a( n = `text` v = `Cash on delivery`

                                        )->end(
                                    )->end(
                                )->end(
                            )->end(

                            )->ele( `WizardStep`
                                )->a( n = `id`        v = `CreditCardStep`
                                )->a( n = `title`     v = `Credit card info`
                                )->a( n = `nextStep`  v = `BillingStep`
                                )->a( n = `activate`  v = client->_event( `CHECK_CREDIT_CARD` )
                                )->a( n = `validated` v = client->_bind( creditcard_validated )
                                )->a( n = `icon`      v = `sap-icon://credit-card`

                                )->tag( `MessageStrip`
                                    )->a( n = `text` v = `Enter at least 3 symbols for credit card name.`

                                )->ele( n = `SimpleForm` ns = `form`
                                    )->a( n = `editable` v = `true`
                                    )->a( n = `layout`   v = `ResponsiveGridLayout`

                                    )->tag( `Label`
                                        )->a( n = `text`     v = `Name on card`
                                        )->a( n = `required` v = `true`
                                    )->tag( `Input`
                                        )->a( n = `value`           v = client->_bind( name )
                                        )->a( n = `liveChange`      v = client->_event( val = `CHECK_CREDIT_CARD` s_ctrl = temp1 )
                                        )->a( n = `valueLiveUpdate` v = `true`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Card number`
                                    )->tag( `Input`
                                        )->a( n = `value` v = client->_bind( cardnumber )
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Security code`
                                    )->tag( `Input`
                                        )->a( n = `value` v = client->_bind( securitycode )
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Expiration date`
                                    )->tag( `DatePicker`
                                        )->a( n = `value` v = client->_bind( expire )

                                )->end(
                            )->end(

                            )->ele( `WizardStep`
                                )->a( n = `id`       v = `BankAccountStep`
                                )->a( n = `title`    v = `Beneficial bank info`
                                )->a( n = `nextStep` v = `BillingStep`
                                )->a( n = `activate` v = client->_event( `PAYMENT_PASSED` )
                                )->a( n = `icon`     v = `sap-icon://official-service`

                                )->ele( `Panel`

                                    )->ele( `headerToolbar`
                                        )->ele( `Toolbar`
                                            )->a( n = `height` v = `0rem`
                                            )->tag( `Title`
                                                )->a( n = `text` v = ``

                                        )->end(
                                    )->end(
                                    )->ele( n = `Grid` ns = `l`
                                        )->a( n = `defaultSpan` v = `L6 M6 S10`
                                        )->a( n = `hSpacing`    v = `2`

                                        )->tag( `Label`
                                            )->a( n = `text`   v = `Beneficiary Name`
                                            )->a( n = `design` v = `Bold`
                                        )->tag( `Label`
                                            )->a( n = `text` v = `Singapore Hardware e-Commerce LTD`
                                        )->tag( `Label`
                                            )->a( n = `text`   v = `Beneficiary Bank`
                                            )->a( n = `design` v = `Bold`
                                        )->tag( `Label`
                                            )->a( n = `text` v = `CITY BANK, SINGAPORE BRANCH`
                                        )->tag( `Label`
                                            )->a( n = `text`   v = `Beneficiary Account Number`
                                            )->a( n = `design` v = `Bold`
                                        )->tag( `Label`
                                            )->a( n = `text` v = `06110702027218`
                                        )->tag( `Label`
                                            )->a( n = `text`   v = `Bank Phone Number`
                                            )->a( n = `design` v = `Bold`
                                        )->tag( `Label`
                                            )->a( n = `text` v = `+65-6224-2622`
                                        )->tag( `Label`
                                            )->a( n = `text`   v = `Bank Email Address`
                                            )->a( n = `design` v = `Bold`
                                        )->tag( `Label`
                                            )->a( n = `text` v = `customerservice@citybank.com`

                                    )->end(
                                )->end(
                            )->end(

                            )->ele( `WizardStep`
                                )->a( n = `id`        v = `CashOnDeliveryStep`
                                )->a( n = `title`     v = `Cash on delivery info`
                                )->a( n = `nextStep`  v = `BillingStep`
                                )->a( n = `activate`  v = client->_event( `CHECK_CASH_ON_DELIVERY` )
                                )->a( n = `validated` v = client->_bind( cod_validated )
                                )->a( n = `icon`      v = `sap-icon://money-bills`

                                )->tag( `MessageStrip`
                                    )->a( n = `text` v = `Enter at least 3 symbols for first name.`

                                )->ele( n = `SimpleForm` ns = `form`
                                    )->a( n = `editable` v = `true`
                                    )->a( n = `layout`   v = `ResponsiveGridLayout`

                                    )->tag( `Label`
                                        )->a( n = `text`     v = `First Name`
                                        )->a( n = `required` v = `true`
                                    )->tag( `Input`
                                        )->a( n = `value`           v = client->_bind( firstname )
                                        )->a( n = `liveChange`      v = client->_event( val = `CHECK_CASH_ON_DELIVERY` s_ctrl = temp2 )
                                        )->a( n = `valueLiveUpdate` v = `true`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Last Name`
                                    )->tag( `Input`
                                        )->a( n = `value` v = client->_bind( lastname )
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Phone Number`
                                    )->tag( `Input`
                                        )->a( n = `value` v = client->_bind( phonenumber )
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Email address`
                                    )->tag( `Input`
                                        )->a( n = `value` v = client->_bind( email )

                                )->end(
                            )->end(

                            )->ele( `WizardStep`
                                )->a( n = `id`              v = `BillingStep`
                                )->a( n = `title`           v = `Billing address`
                                )->a( n = `subsequentSteps` v = `DeliveryAddressStep, DeliveryTypeStep`
                                )->a( n = `activate`        v = client->_event( `CHECK_BILLING` )
                                )->a( n = `complete`        v = client->_event( `BILLING_COMPLETE` )
                                )->a( n = `validated`       v = client->_bind( billing_validated )
                                )->a( n = `icon`            v = `sap-icon://sales-quote`

                                )->tag( `MessageStrip`
                                    )->a( n = `text` v = `Enter at least 3 symbols for each required field`

                                )->ele( n = `SimpleForm` ns = `form`
                                    )->a( n = `editable` v = `true`
                                    )->a( n = `layout`   v = `ResponsiveGridLayout`

                                    )->tag( `Label`
                                        )->a( n = `text` v = `Delivery address is different`
                                    )->tag( `CheckBox`
                                        )->a( n = `selected` v = client->_bind( differentdeliveryaddress )
                                        )->a( n = `select`   v = client->_event( `SET_DIFFERENT_DELIVERY` )
                                    )->tag( `Label`
                                        )->a( n = `text`     v = `Address`
                                        )->a( n = `required` v = `true`
                                    )->tag( `Input`
                                        )->a( n = `value`           v = client->_bind( address )
                                        )->a( n = `liveChange`      v = client->_event( val = `CHECK_BILLING` s_ctrl = temp3 )
                                        )->a( n = `valueLiveUpdate` v = `true`
                                    )->tag( `Label`
                                        )->a( n = `text`     v = `City`
                                        )->a( n = `required` v = `true`
                                    )->tag( `Input`
                                        )->a( n = `value`           v = client->_bind( city )
                                        )->a( n = `liveChange`      v = client->_event( val = `CHECK_BILLING` s_ctrl = temp4 )
                                        )->a( n = `valueLiveUpdate` v = `true`
                                    )->tag( `Label`
                                        )->a( n = `text`     v = `Zip Code`
                                        )->a( n = `required` v = `true`
                                    )->tag( `Input`
                                        )->a( n = `value`           v = client->_bind( zipcode )
                                        )->a( n = `liveChange`      v = client->_event( val = `CHECK_BILLING` s_ctrl = temp5 )
                                        )->a( n = `valueLiveUpdate` v = `true`
                                    )->tag( `Label`
                                        )->a( n = `text`     v = `Country`
                                        )->a( n = `required` v = `true`
                                    )->tag( `Input`
                                        )->a( n = `value`           v = client->_bind( country )
                                        )->a( n = `liveChange`      v = client->_event( val = `CHECK_BILLING` s_ctrl = temp6 )
                                        )->a( n = `valueLiveUpdate` v = `true`
                                    )->tag( `Label`
                                        )->a( n = `text`     v = `Note`
                                        )->a( n = `required` v = `false`
                                    )->tag( `TextArea`
                                        )->a( n = `rows`  v = `8`
                                        )->a( n = `value` v = client->_bind( note )

                                )->end(
                            )->end(

                            )->ele( `WizardStep`
                                )->a( n = `id`       v = `DeliveryAddressStep`
                                )->a( n = `title`    v = `Delivery address`
                                )->a( n = `nextStep` v = `DeliveryTypeStep`
                                )->a( n = `activate` v = client->_event( `BILLING_PASSED` )
                                )->a( n = `icon`     v = `sap-icon://sales-quote`

                                )->ele( n = `SimpleForm` ns = `form`
                                    )->a( n = `editable` v = `true`
                                    )->a( n = `layout`   v = `ResponsiveGridLayout`

                                    )->tag( `Label`
                                        )->a( n = `text` v = `Address`
                                    )->tag( `Input`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `City`
                                    )->tag( `Input`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Zip Code`
                                    )->tag( `Input`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Country`
                                    )->tag( `Input`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Note`
                                    )->tag( `TextArea`
                                        )->a( n = `rows` v = `8`

                                )->end(
                            )->end(

                            )->ele( `WizardStep`
                                )->a( n = `id`       v = `DeliveryTypeStep`
                                )->a( n = `title`    v = `Delivery type`
                                )->a( n = `activate` v = client->_event( `BILLING_PASSED` )
                                )->a( n = `icon`     v = `sap-icon://insurance-car`

                                )->tag( `Text`
                                    )->a( n = `class` v = `sapUiSmallMarginBottom`
                                    )->a( n = `text`  v = `Standard delivery will be delivered within 5 workdays. Be aware, that around high-season sales, standard delivery may take up to one additional ` &&
                                                          `day. Express delivery is delivered within 36 hours. A service fee of 5.49 EUR is charged for Express delivery on a workday. For a holiday ` &&
                                                          `delivery, the service fee is 8,00 EUR. Express delivery is only available for inland deliveries. All service fees vary for deliveries  abroad.`

                                )->ele( `HBox`
                                    )->a( n = `alignItems`     v = `Center`
                                    )->a( n = `justifyContent` v = `Center`
                                    )->a( n = `width`          v = `100%`

                                    )->ele( `SegmentedButton`
                                        )->a( n = `selectedKey` v = client->_bind( selecteddeliverymethod )

                                        )->ele( `items`
                                            )->tag( `SegmentedButtonItem`
                                                )->a( n = `key`  v = `Standard Delivery`
                                                )->a( n = `text` v = `Standard`
                                            )->tag( `SegmentedButtonItem`
                                                )->a( n = `key`  v = `Express Delivery`
                                                )->a( n = `text` v = `Express`

                                        )->end(
                                    )->end(
                                )->end(
                            )->end(
                        )->end(
                    )->end(
                    )->ele( `footer`
                        )->ele( `OverflowToolbar`
                            )->tag( `ToolbarSpacer`
                            )->tag( `Button`
                                )->a( n = `text`  v = `Cancel`
                                )->a( n = `press` v = client->_event( `WIZARD_CANCEL` )

                        )->end(
                    )->end(
                )->end(

                )->ele( `Page`
                    )->a( n = `id`         v = `wizardBranchingReviewPage`
                    )->a( n = `showHeader` v = `false`

                    )->ele( `content`
                        )->ele( n = `SimpleForm` ns = `form`
                            )->a( n = `title`    v = `1. List of products`
                            )->a( n = `editable` v = `false`
                            )->a( n = `layout`   v = `ResponsiveGridLayout`

                            )->ele( `List`
                                )->a( n = `mode`                v = `None`
                                )->a( n = `items`               v = client->_bind( productcollection )
                                )->a( n = `enableBusyIndicator` v = `true`

                                )->tag( `StandardListItem`
                                    )->a( n = `title`            v = `{NAME}`
                                    )->a( n = `type`             v = `Active`
                                    )->a( n = `description`      v = `{DESCRIPTION}`
                                    )->a( n = `icon`             v = `{PRODUCTPICURL}`
                                    )->a( n = `info`             v = `{PRICE} {CURRENCYCODE}`
                                    )->a( n = `iconDensityAware` v = `false`
                                    )->a( n = `iconInset`        v = `false`

                            )->end(
                            )->ele( `ObjectHeader`
                                )->a( n = `title`      v = `Total`
                                )->a( n = `number`     v = client->_bind( productstotalprice )
                                )->a( n = `numberUnit` v = `EUR`

                                )->ele( `attributes`
                                    )->tag( `ObjectAttribute`
                                        )->a( n = `press`  v = client->_event( `EDIT_LIST` )
                                        )->a( n = `active` v = `true`
                                        )->a( n = `text`   v = `Edit`

                                )->end(
                            )->end(
                        )->end(

                        )->ele( n = `SimpleForm` ns = `form`
                            )->a( n = `title`    v = `2. Payment type`
                            )->a( n = `editable` v = `false`
                            )->a( n = `layout`   v = `ResponsiveGridLayout`

                            )->ele( n = `content` ns = `form`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Chosen payment type`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( selectedpayment )
                                )->tag( `Link`
                                    )->a( n = `press` v = client->_event( `EDIT_PAYMENT_TYPE` )
                                    )->a( n = `text`  v = `Edit`

                            )->end(
                        )->end(

                        )->ele( n = `SimpleForm` ns = `form`
                            )->a( n = `visible`  v = |\{= ${ client->_bind( selectedpayment ) }==='Credit Card' ? true : false \}|
                            )->a( n = `title`    v = `3. Credit Card payment`
                            )->a( n = `editable` v = `false`
                            )->a( n = `layout`   v = `ResponsiveGridLayout`

                            )->ele( n = `content` ns = `form`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Name on card`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( name )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Card number`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( cardnumber )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Security code`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( securitycode )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Expiration date`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( expire )
                                )->tag( `Link`
                                    )->a( n = `press` v = client->_event( `EDIT_CREDIT_CARD` )
                                    )->a( n = `text`  v = `Edit`

                            )->end(
                        )->end(

                        )->ele( n = `SimpleForm` ns = `form`
                            )->a( n = `visible`  v = |\{= ${ client->_bind( selectedpayment ) }==='Bank Transfer' ? true : false \}|
                            )->a( n = `title`    v = `3. Bank Transfer`
                            )->a( n = `editable` v = `false`
                            )->a( n = `layout`   v = `ResponsiveGridLayout`

                            )->ele( n = `content` ns = `form`
                                )->ele( n = `Grid` ns = `l`
                                    )->a( n = `defaultSpan` v = `L6 M6 S10`
                                    )->a( n = `hSpacing`    v = `2`

                                    )->tag( `Label`
                                        )->a( n = `text`   v = `Beneficiary Name`
                                        )->a( n = `design` v = `Bold`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Singapore Hardware e-Commerce LTD`
                                    )->tag( `Label`
                                        )->a( n = `text`   v = `Beneficiary Bank`
                                        )->a( n = `design` v = `Bold`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `CITY BANK, SINGAPORE BRANCH`
                                    )->tag( `Label`
                                        )->a( n = `text`   v = `Beneficiary Account Number`
                                        )->a( n = `design` v = `Bold`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `06110702027218`
                                    )->tag( `Label`
                                        )->a( n = `text`   v = `Bank Phone Number`
                                        )->a( n = `design` v = `Bold`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `+65-6224-2622`
                                    )->tag( `Label`
                                        )->a( n = `text`   v = `Bank Email Address`
                                        )->a( n = `design` v = `Bold`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `customerservice@citybank.com`

                                )->end(
                            )->end(
                        )->end(

                        )->ele( n = `SimpleForm` ns = `form`
                            )->a( n = `visible`  v = |\{= ${ client->_bind( selectedpayment ) }==='Cash on Delivery' ? true : false \}|
                            )->a( n = `title`    v = `3. Cash on delivery`
                            )->a( n = `editable` v = `false`
                            )->a( n = `layout`   v = `ResponsiveGridLayout`

                            )->ele( n = `content` ns = `form`
                                )->tag( `Label`
                                    )->a( n = `text` v = `First Name`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( firstname )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Last Name`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( lastname )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Phone number`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( phonenumber )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Email address`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( email )
                                )->tag( `Link`
                                    )->a( n = `press` v = client->_event( `EDIT_CASH_ON_DELIVERY` )
                                    )->a( n = `text`  v = `Edit`

                            )->end(
                        )->end(

                        )->ele( n = `SimpleForm` ns = `form`
                            )->a( n = `title`    v = `4. Billing Address`
                            )->a( n = `editable` v = `false`
                            )->a( n = `layout`   v = `ResponsiveGridLayout`

                            )->ele( n = `content` ns = `form`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Address`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( address )
                                )->tag( `Label`
                                    )->a( n = `text` v = `City`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( city )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Zip Code`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( zipcode )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Country`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( country )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Note`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( note )
                                )->tag( `Link`
                                    )->a( n = `press` v = client->_event( `EDIT_BILLING` )
                                    )->a( n = `text`  v = `Edit`

                            )->end(
                        )->end(

                        )->ele( n = `SimpleForm` ns = `form`
                            )->a( n = `title`    v = `5. Delivery type`
                            )->a( n = `editable` v = `false`
                            )->a( n = `layout`   v = `ResponsiveGridLayout`

                            )->ele( n = `content` ns = `form`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Chosen delivery type`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( selecteddeliverymethod )
                                )->tag( `Link`
                                    )->a( n = `press` v = client->_event( `EDIT_DELIVERY_TYPE` )
                                    )->a( n = `text`  v = `Edit`

                            )->end(
                        )->end(
                    )->end(

                    )->ele( `footer`
                        )->ele( `Bar`
                            )->ele( `contentRight`
                                )->tag( `Button`
                                    )->a( n = `text`  v = `Submit`
                                    )->a( n = `press` v = client->_event( `WIZARD_SUBMIT` )
                                )->tag( `Button`
                                    )->a( n = `text`  v = `Cancel`
                                    )->a( n = `press` v = client->_event( `WIZARD_CANCEL` ) ).

    client->view_display( view->stringify( ) ).

    " The two branch associations are live control state: a rebuilt view resets
    " them to what the XML declares, and BillingStep declares NO nextStep at all
    " (only subsequentSteps), while `selectedpayment` and
    " `differentdeliveryaddress` are bound class state that survives. So without
    " this the wizard comes back branching to the static CreditCardStep whatever
    " the user chose, and BillingStep comes back with no branch at all - the
    " "wizard is in branching mode and no next step is defined" throw again.
    " Both methods are pure: they compute from the surviving fields and issue
    " the wire, so re-issuing on every render is idempotent. Found by the
    " linter's new control-state-lost-on-rebuild rule, which is exactly the
    " class it was written for
    branch_payment( ).
    branch_delivery( ).

  ENDMETHOD.


  METHOD on_event.
        DATA del_title TYPE string.
          DATA temp2 TYPE string_table.
          DATA temp4 TYPE string_table.
          DATA temp6 TYPE string_table.
        DATA temp1 TYPE xsdboolean.
        DATA temp3 TYPE xsdboolean.
        DATA temp5 TYPE xsdboolean.
        DATA temp8 TYPE string_table.
        DATA temp10 TYPE string_table.
        DATA temp12 TYPE string_table.
          DATA temp14 TYPE string_table.

    CASE client->get_event( ).

      WHEN `DELETE_ITEM`.
        " handleDelete removes the row by its title, but never the last one
        
        del_title = client->get_event_arg( ).
        IF lines( productcollection ) > 1.
          DELETE productcollection WHERE name = del_title.
          total_calc( ).
        ENDIF.

      WHEN `GOTO_PAYMENT`.
        " goToPaymentStep - re-asserts the branch the choice already sent
        branch_payment( ).

      WHEN `BILLING_COMPLETE`.
        " billingAddressComplete - re-asserts the branch the arrival already sent
        branch_delivery( ).

      WHEN `SET_PAYMENT`.
        " setDiscardableProperty: only ask once the wizard is past the step
        IF payment_passed = abap_true.
          pending_discard = `PaymentTypeStep`.
          
          CLEAR temp2.
          INSERT `YES` INTO TABLE temp2.
          INSERT `NO` INTO TABLE temp2.
          client->message_box_display( text    = `Are you sure you want to change the payment type ? This will discard your progress.`
                                       type    = `warning`
                                       actions = temp2
                                       onclose = `DISCARD_DECIDE` ).
        ELSE.
          prev_payment = selectedpayment.
          branch_payment( ).
        ENDIF.

      WHEN `SET_DIFFERENT_DELIVERY`.
        IF billing_passed = abap_true.
          pending_discard = `BillingStep`.
          
          CLEAR temp4.
          INSERT `YES` INTO TABLE temp4.
          INSERT `NO` INTO TABLE temp4.
          client->message_box_display( text    = `Are you sure you want to change the delivery address ? This will discard your progress`
                                       type    = `warning`
                                       actions = temp4
                                       onclose = `DISCARD_DECIDE` ).
        ELSE.
          prev_diff_delivery = differentdeliveryaddress.
          branch_delivery( ).
        ENDIF.

      WHEN `DISCARD_DECIDE`.
        IF client->get_event_arg( ) = `YES`.
          
          CLEAR temp6.
          INSERT `ShoppingCartWizard` INTO TABLE temp6.
          INSERT `discardProgress` INTO TABLE temp6.
          INSERT pending_discard INTO TABLE temp6.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = temp6 ).
          IF pending_discard = `PaymentTypeStep`.
            prev_payment   = selectedpayment.
            payment_passed = abap_false.
            branch_payment( ).
          ELSE.
            prev_diff_delivery = differentdeliveryaddress.
            billing_passed     = abap_false.
            branch_delivery( ).
          ENDIF.
        ELSEIF pending_discard = `PaymentTypeStep`.
          " the NO branch restores the remembered value
          selectedpayment = prev_payment.
        ELSE.
          differentdeliveryaddress = prev_diff_delivery.
        ENDIF.

      WHEN `CHECK_CREDIT_CARD`.
        payment_passed       = abap_true.
        
        temp1 = boolc( strlen( name ) >= 3 ).
        creditcard_validated = temp1.

      WHEN `CHECK_CASH_ON_DELIVERY`.
        payment_passed = abap_true.
        
        temp3 = boolc( strlen( firstname ) >= 3 ).
        cod_validated  = temp3.

      WHEN `PAYMENT_PASSED`.
        payment_passed = abap_true.

      WHEN `CHECK_BILLING`.
        " also the step's activate wire: the branch must stand before the Next
        " button can ever appear, and only this answer can make it appear
        branch_delivery( ).
        payment_passed    = abap_true.
        
        temp5 = boolc( strlen( address ) >= 3 AND strlen( city ) >= 3 AND strlen( zipcode ) >= 3 AND strlen( country ) >= 3 ).
        billing_validated = temp5.

      WHEN `BILLING_PASSED`.
        billing_passed = abap_true.

      WHEN `WIZARD_COMPLETE`.
        " completedHandler: NavContainer to the review page
        
        CLEAR temp8.
        INSERT `wizardNavContainer` INTO TABLE temp8.
        INSERT `to` INTO TABLE temp8.
        INSERT `wizardBranchingReviewPage` INTO TABLE temp8.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp8 ).

      WHEN `EDIT_LIST`.
        nav_back_to_step( `ContentsStep` ).

      WHEN `EDIT_PAYMENT_TYPE`.
        nav_back_to_step( `PaymentTypeStep` ).

      WHEN `EDIT_CREDIT_CARD`.
        nav_back_to_step( `CreditCardStep` ).

      WHEN `EDIT_CASH_ON_DELIVERY`.
        nav_back_to_step( `CashOnDeliveryStep` ).

      WHEN `EDIT_BILLING`.
        nav_back_to_step( `BillingStep` ).

      WHEN `EDIT_DELIVERY_TYPE`.
        nav_back_to_step( `DeliveryTypeStep` ).

      WHEN `WIZARD_CANCEL`.
        
        CLEAR temp10.
        INSERT `YES` INTO TABLE temp10.
        INSERT `NO` INTO TABLE temp10.
        client->message_box_display( text    = `Are you sure you want to cancel your purchase?`
                                     type    = `warning`
                                     actions = temp10
                                     onclose = `WIZARD_CLOSED` ).

      WHEN `WIZARD_SUBMIT`.
        
        CLEAR temp12.
        INSERT `YES` INTO TABLE temp12.
        INSERT `NO` INTO TABLE temp12.
        client->message_box_display( text    = `Are you sure you want to submit your report?`
                                     type    = `confirm`
                                     actions = temp12
                                     onclose = `WIZARD_CLOSED` ).

      WHEN `WIZARD_CLOSED`.
        " _handleMessageBoxOpen: YES discards the progress and goes back to the list
        IF client->get_event_arg( ) = `YES`.
          
          CLEAR temp14.
          INSERT `ShoppingCartWizard` INTO TABLE temp14.
          INSERT `discardProgress` INTO TABLE temp14.
          INSERT `ContentsStep` INTO TABLE temp14.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = temp14 ).
          payment_passed = abap_false.
          billing_passed = abap_false.
          nav_back_to_step( `ContentsStep` ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD branch_payment.

    " goToPaymentStep's branch, sent as soon as the payment type is CHOSEN,
    " and again from view_display( ) - the association is live control state a
    " rebuilt view resets, so the call sites below are not the whole story.
    " WizardStep._complete fires complete and then calls
    " Wizard._handleNextButtonPress in the SAME tick, so a nextStep that only
    " arrives with the complete round trip is one press too late.
    DATA temp16 TYPE string.
    DATA next LIKE temp16.
    DATA temp17 TYPE string_table.
    CASE selectedpayment.
      WHEN `Credit Card`.
        temp16 = `CreditCardStep`.
      WHEN `Bank Transfer`.
        temp16 = `BankAccountStep`.
      WHEN OTHERS.
        temp16 = `CashOnDeliveryStep`.
    ENDCASE.
    
    next = temp16.
    
    CLEAR temp17.
    INSERT `PaymentTypeStep` INTO TABLE temp17.
    INSERT `setNextStep` INTO TABLE temp17.
    INSERT next INTO TABLE temp17.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp17 ).

  ENDMETHOD.


  METHOD branch_delivery.

    " billingAddressComplete's branch, sent from view_display( ) too - BillingStep
    " declares NO nextStep, so after a rebuild it has no branch at all until this
    " runs. Also sent on the step's activate wire and on
    " every change of the checkbox - for the same reason as branch_payment
    DATA temp19 TYPE string.
    DATA next LIKE temp19.
    DATA temp20 TYPE string_table.
    IF differentdeliveryaddress = abap_true.
      temp19 = `DeliveryAddressStep`.
    ELSE.
      temp19 = `DeliveryTypeStep`.
    ENDIF.
    
    next = temp19.
    
    CLEAR temp20.
    INSERT `BillingStep` INTO TABLE temp20.
    INSERT `setNextStep` INTO TABLE temp20.
    INSERT next INTO TABLE temp20.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp20 ).

  ENDMETHOD.


  METHOD nav_back_to_step.

    " _navBackToStep: back to the wizard content page, then goToStep
    DATA temp22 TYPE string_table.
    DATA temp24 TYPE string_table.
    CLEAR temp22.
    INSERT `wizardNavContainer` INTO TABLE temp22.
    INSERT `to` INTO TABLE temp22.
    INSERT `wizardContentPage` INTO TABLE temp22.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp22 ).
    
    CLEAR temp24.
    INSERT `ShoppingCartWizard` INTO TABLE temp24.
    INSERT `goToStep` INTO TABLE temp24.
    INSERT step_id INTO TABLE temp24.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp24 ).

  ENDMETHOD.


  METHOD total_calc.

    " a plain LOOP, not REDUCE: the downport rule only rewrites a REDUCE whose
    " result type is named (REDUCE i( ... ) elsewhere in the corpus downports
    " fine); a REDUCE #( ) is left standing and reaches the v702 gate as a
    " parser_error. p LENGTH 8 DECIMALS 2 cannot be named inline, so the sum
    " is accumulated here instead
    DATA temp26 LIKE productstotalprice.
    DATA row LIKE LINE OF productcollection.
    CLEAR temp26.
    productstotalprice = temp26.
    
    LOOP AT productcollection INTO row.
      productstotalprice = productstotalprice + row-price.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    " attachRequestCompleted keeps the FIRST FIVE rows of the mock collection
    " and seeds the payment / delivery defaults
    DATA temp27 TYPE z2ui5_cl_smpc_app_535=>ty_t_product.
    DATA temp28 LIKE LINE OF temp27.
    CLEAR temp27.
    
    temp28-name = `Notebook Basic 15`.
    temp28-description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp28-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp28-price = '956.00'.
    temp28-currencycode = `EUR`.
    INSERT temp28 INTO TABLE temp27.
    temp28-name = `Notebook Basic 17`.
    temp28-description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp28-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp28-price = '1249.00'.
    temp28-currencycode = `EUR`.
    INSERT temp28 INTO TABLE temp27.
    temp28-name = `Notebook Basic 18`.
    temp28-description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp28-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp28-price = '1570.00'.
    temp28-currencycode = `EUR`.
    INSERT temp28 INTO TABLE temp27.
    temp28-name = `Notebook Basic 19`.
    temp28-description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp28-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp28-price = '1650.00'.
    temp28-currencycode = `EUR`.
    INSERT temp28 INTO TABLE temp27.
    temp28-name = `ITelO Vault`.
    temp28-description = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp28-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp28-price = '299.00'.
    temp28-currencycode = `EUR`.
    INSERT temp28 INTO TABLE temp27.
    productcollection = temp27.

    selectedpayment          = `Credit Card`.
    selecteddeliverymethod   = `Standard Delivery`.
    differentdeliveryaddress = abap_false.
    prev_payment             = selectedpayment.
    prev_diff_delivery       = differentdeliveryaddress.

    total_calc( ).

  ENDMETHOD.

ENDCLASS.
