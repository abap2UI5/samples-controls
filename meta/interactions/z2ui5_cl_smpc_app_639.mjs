// the payments filter: DynamicDateRange change -> valueState + binding_call filter
// Driven like a user selection: setValue + fireChange({ value, valid }), the
// event the DynamicDateRange itself fires when its popover's Apply commits.
// The wire is ${$source>}.toDates(value)[0|1]; the backend answers with the
// valueState and a binding_call filter on the payments-table items.
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

const fire = (page, value, valid) => page.evaluate(([v, ok]) => {
  const ddr = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .find((c) => c.getMetadata().getName() === 'sap.m.DynamicDateRange');
  // the values travel as [y, m, d] triples - a Date does not survive evaluate( )
  const value = v && { operator: v.operator, values: v.values.map((d) => new Date(d[0], d[1], d[2])) };
  ddr.setValue(value);
  ddr.fireChange({ value, valid: ok });
}, [value, valid]);

const state = ([r, s]) => {
  const t = ui5All().find((x) => /payments-table$/.test(x.getId()) && !x.bIsDestroyed);
  const d = ui5All().find((x) => x.getMetadata().getName() === 'sap.m.DynamicDateRange' && !x.bIsDestroyed);
  return !!t && !!d && t.getItems().length === r && d.getValueState() === s;
};

export default async (page, expect) => {
  await waitForUi5(page, state, 'the payments-table never came up with its 16 rows and valueState None', [16, 'None']);

  // an invalid entry: setValueState(Error) round-trips, the rows stay
  await fire(page, { operator: 'DATERANGE', values: [[2021, 5, 1], [2021, 5, 30]] }, false);
  await waitForUi5(page, state, 'valid=false never set the valueState to Error', [16, 'Error']);

  // a June 2021 range: BT over the two toDates dates keeps only the June 2021 rows
  await fire(page, { operator: 'DATERANGE', values: [[2021, 5, 1], [2021, 5, 30]] }, true);
  await waitForUi5(page, state, 'the June 2021 DATERANGE never filtered the payments-table to its 2 June 2021 rows (toDates -> BT binding_call)', [2, 'None']);

  // FROM 9 June 2021 maps to GT on toDates()[0]
  await fire(page, { operator: 'FROM', values: [[2021, 5, 9]] }, true);
  await waitForUi5(page, state, 'FROM 9 June 2021 never filtered to the 15 rows after 9 June 2021 00:00 (GT)', [15, 'None']);

  // a cleared value sends no dates and clears the filter
  await fire(page, null, true);
  await waitForUi5(page, state, 'clearing the value never cleared the filter', [16, 'None']);
};
