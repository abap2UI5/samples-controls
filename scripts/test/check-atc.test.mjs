// The two decisions of check-atc that are easy to get wrong and were: the
// comment stripper (which quotes open a literal) and the text-symbol rule
// (when a symbol is a PARAMETER). Both are exported for exactly this.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { code, textSymbolArg } from '../check-atc.mjs';

test('code(): a " inside a backtick literal is text, not a comment', () => {
  assert.equal(code('marker = `"text":"`. " trailing'), 'marker = `"text":"`. ');
  assert.equal(code("lv = '\"'. \" c"), "lv = '\"'. ");
  assert.equal(code('lv = |"{ x }"|. " c'), 'lv = |"{ x }"|. ');
  assert.equal(code('DATA x. " a comment'), 'DATA x. ');
});

test('text symbol: a parameter of a method call is reported', () => {
  assert.notEqual(textSymbolArg("client->message_toast_display( text = 'Saved'(001) )."), -1);
  assert.notEqual(textSymbolArg("client->message_toast_display( 'Saved'(001) )."), -1, 'positional');
  assert.notEqual(textSymbolArg("view->a( n = `text` v = 'Name'(A01) )."), -1, 'alphanumeric id');
  assert.notEqual(textSymbolArg("meth( a = 1 b = 'x'(001) )."), -1, 'second named parameter');
});

test('text symbol: an assignment, a component, a comparison, a template are not', () => {
  assert.equal(textSymbolArg("lv_x = 'y'(001)."), -1, 'plain assignment');
  assert.equal(textSymbolArg("t = VALUE #( text = 'Save'(001) )."), -1, 'component of a constructor');
  assert.equal(textSymbolArg("t = VALUE ty_t_opt( ( name = 'x'(001) ) )."), -1, 'typed constructor');
  assert.equal(textSymbolArg("IF xsdbool( a = 'x'(001) ) = abap_true."), -1, 'comparison');
  assert.equal(textSymbolArg("IF ( a = 'x'(001) )."), -1, 'free parenthesis');
  assert.equal(textSymbolArg("meth( val = |{ 'x'(001) }| )."), -1, 'string template');
  assert.equal(textSymbolArg("meth( val = `a` && 'x'(001) )."), -1, 'concatenation');
  assert.equal(textSymbolArg("meth( val = COND #( WHEN a = 1 THEN 'x'(001) ) )."), -1, 'inside COND');
});
