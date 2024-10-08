import { JSDOM } from 'jsdom';
import { describe, it, expect } from 'vitest';

import { KM } from '../src';

const dom = new JSDOM();
(global as any).window = dom.window;

describe('KM', () => {
  it('should have `android` property', () => {
    expect(KM.android).not.toBeUndefined();
  });

  it('should have `iOS` property', () => {
    expect(KM.iOS).not.toBeUndefined();
  });

  it('should have `flutter` property', () => {
    expect(KM.flutter).not.toBeUndefined();
  });

  it('should have `browser` property', () => {
    expect(KM.browser).not.toBeUndefined();
  });
});
