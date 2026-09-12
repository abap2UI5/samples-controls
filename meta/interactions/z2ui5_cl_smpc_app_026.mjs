// FlexBoxNested: six nested flex items whose backgrounds come from the
// sample's style.css injected through a core:HTML <style> — so the proof is a
// COMPUTED background colour, which only the injected rule can produce
export default async (page, expect) => {
  for (const n of ['1', '2', '3', '4', '5', '6']) {
    await expect(page.locator('.nestedFlexboxes h2'), `the h2 "${n}"`).toContainText(n);
  }
  const bg = await page.evaluate(() => {
    const el = document.querySelector('.nestedFlexboxes .item1');
    return el ? getComputedStyle(el).backgroundColor : null;
  });
  if (bg !== 'rgb(209, 219, 189)') throw new Error(`the injected .item1 rule did not apply — background is ${bg}, not rgb(209, 219, 189)`);
  const h2 = await page.evaluate(() => {
    const el = document.querySelector('.nestedFlexboxes h2');
    return el ? getComputedStyle(el).color : null;
  });
  if (h2 !== 'rgb(50, 54, 58)') throw new Error(`the injected h2 colour did not apply — got ${h2}`);
};
