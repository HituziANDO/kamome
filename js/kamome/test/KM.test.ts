import { describe, it, expect, vi, beforeAll, beforeEach, afterEach } from 'vitest';

import { KM, WebPlatform } from '../src';
import { KamomeError } from '../src/KamomeError';
import { VERSION_CODE } from '../src/VERSION_CODE';
import { undefinedToNull } from '../src/util/undefinedToNull';
import { uuid } from '../src/util/uuid';

// Trigger KM initialization.
// The KM module registers a DOMContentLoaded listener at import time,
// but in vitest's jsdom environment the event has already fired before imports,
// so we dispatch it manually.
window.dispatchEvent(new Event('DOMContentLoaded'));

function waitForReady(timeout = 5000): Promise<void> {
  return new Promise<void>((resolve, reject) => {
    let done = false;
    let pollTimer: ReturnType<typeof setTimeout> | null = null;

    const cleanup = () => {
      clearTimeout(timer);
      if (pollTimer !== null) {
        clearTimeout(pollTimer);
        pollTimer = null;
      }
    };

    const timer = setTimeout(() => {
      if (done) {
        return;
      }
      done = true;
      cleanup();
      reject(new Error('KM did not become ready'));
    }, timeout);

    const check = () => {
      if (done) {
        return;
      }

      if (KM.isReady()) {
        done = true;
        cleanup();
        resolve();
      } else {
        pollTimer = setTimeout(check, 10);
      }
    };
    check();
  });
}

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

  it('should return VERSION_CODE as a number', () => {
    expect(KM.VERSION_CODE).toBe(VERSION_CODE);
    expect(typeof KM.VERSION_CODE).toBe('number');
  });

  it('should expose KamomeError constants via Error property', () => {
    expect(KM.Error).toBe(KamomeError);
    expect(KM.Error.requestTimeout).toBe('RequestTimeout');
    expect(KM.Error.rejected).toBe('Rejected');
    expect(KM.Error.canceled).toBe('Canceled');
  });

  it('should report no native clients in test environment', () => {
    expect(KM.hasNoClients()).toBe(true);
  });

  it('should allow setting default request timeout', () => {
    KM.setDefaultRequestTimeout(5000);
    KM.setDefaultRequestTimeout(10000); // restore
  });

  it('should allow setting and clearing ready event listener', () => {
    const listener = vi.fn();
    KM.setReadyEventListener(listener);
    KM.setReadyEventListener(null);
  });
});

describe('KM.addReceiver / removeReceiver', () => {
  afterEach(() => {
    KM.removeReceiver('testCmd');
  });

  it('should return KM instance for chaining', () => {
    const result = KM.addReceiver('testCmd', vi.fn());
    expect(result).toBeDefined();
  });

  it('should remove a receiver without errors', () => {
    KM.addReceiver('testCmd', vi.fn());
    const result = KM.removeReceiver('testCmd');
    expect(result).toBeDefined();
  });

  it('should not throw when removing a non-existent receiver', () => {
    expect(() => KM.removeReceiver('nonExistent')).not.toThrow();
  });
});

describe('KM.onComplete', () => {
  it('should return null for a non-existent request', () => {
    expect(KM.onComplete({ value: 42 }, 'unknown-id')).toBeNull();
  });

  it('should return null when result is null', () => {
    expect(KM.onComplete(null, 'unknown-id')).toBeNull();
  });
});

describe('KM.onError', () => {
  it('should return null for a non-existent request', () => {
    expect(KM.onError('some error', 'unknown-id')).toBeNull();
  });

  it('should return null when error message is null', () => {
    expect(KM.onError(null, 'unknown-id')).toBeNull();
  });
});

describe('KM.onReceive', () => {
  afterEach(() => {
    KM.removeReceiver('testReceive');
  });

  it('should return null when no receiver is registered', () => {
    expect(KM.onReceive('nonExistent', null, 'callback-id')).toBeNull();
  });

  it('should invoke the registered receiver with correct data', () => {
    const receiver = vi.fn((_data, resolve) => resolve(null));
    KM.addReceiver('testReceive', receiver);

    KM.onReceive('testReceive', { key: 'value' }, 'cb-id');

    expect(receiver).toHaveBeenCalledWith(
      { key: 'value' },
      expect.any(Function),
      expect.any(Function),
    );
  });

  it('should invoke the receiver with null data', () => {
    const receiver = vi.fn((_data, resolve) => resolve(null));
    KM.addReceiver('testReceive', receiver);

    KM.onReceive('testReceive', null, 'cb-id');

    expect(receiver).toHaveBeenCalledWith(null, expect.any(Function), expect.any(Function));
  });
});

describe('KM.send (browser mode)', () => {
  beforeAll(async () => {
    await waitForReady();
  });

  afterEach(() => {
    KM.browser.removeCommand('testCmd');
  });

  it('should be ready after initialization', () => {
    expect(KM.isReady()).toBe(true);
  });

  it('should resolve with data from a browser command', async () => {
    KM.browser.addCommand('testCmd', (data, resolve) => {
      resolve({ echo: data?.msg });
    });

    const result = await KM.send('testCmd', { msg: 'hello' });
    expect(result).toEqual({ echo: 'hello' });
  });

  it('should reject when browser command calls reject', async () => {
    KM.browser.addCommand('testCmd', (_data, _resolve, reject) => {
      reject('test error');
    });

    await expect(KM.send('testCmd')).rejects.toContain('Rejected');
  });

  it('should pass null data to handler when data is omitted', async () => {
    KM.browser.addCommand('testCmd', (data, resolve) => {
      resolve({ received: data });
    });

    const result = await KM.send('testCmd');
    expect(result).toEqual({ received: null });
  });

  it('should invoke each handler exactly once when multiple sends are queued synchronously', async () => {
    const handler1 = vi.fn((_data, resolve) => resolve({ id: 1 }));
    const handler2 = vi.fn((_data, resolve) => resolve({ id: 2 }));
    const handler3 = vi.fn((_data, resolve) => resolve({ id: 3 }));
    KM.browser.addCommand('cmdA', handler1);
    KM.browser.addCommand('cmdB', handler2);
    KM.browser.addCommand('cmdC', handler3);

    try {
      const results = await Promise.all([KM.send('cmdA'), KM.send('cmdB'), KM.send('cmdC')]);

      expect(results).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }]);
      expect(handler1).toHaveBeenCalledTimes(1);
      expect(handler2).toHaveBeenCalledTimes(1);
      expect(handler3).toHaveBeenCalledTimes(1);
    } finally {
      KM.browser.removeCommand('cmdA');
      KM.browser.removeCommand('cmdB');
      KM.browser.removeCommand('cmdC');
    }
  });
});

describe('KM.send timeout', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    KM.browser.removeCommand('slowCmd');
    vi.useRealTimers();
  });

  it('should reject with RequestTimeout when command does not respond in time', async () => {
    KM.browser.addCommand('slowCmd', () => {
      // Intentionally never resolves or rejects
    });

    // Capture rejection immediately to avoid unhandled rejection warnings.
    const promise = KM.send('slowCmd', null, 500).catch((e: string) => e);

    // Fire execCommand's setTimeout(0)
    await vi.advanceTimersByTimeAsync(1);
    // Fire the request timeout
    await vi.advanceTimersByTimeAsync(500);

    const error = await promise;
    expect(error).toContain('RequestTimeout');
    expect(error).toContain('slowCmd');
  });

  it('should disable timeout when timeoutMillis is 0', async () => {
    // Reduce the default so the old buggy `||` fallback (treating 0 as falsy)
    // would fire a short timeout. Under the fix, 0 must disable the timer.
    KM.setDefaultRequestTimeout(100);
    try {
      let resolveHandler: (() => void) | null = null;
      KM.browser.addCommand('slowCmd', (_data, resolve) => {
        resolveHandler = () => resolve({ done: true });
      });

      const sendPromise = KM.send('slowCmd', null, 0);

      // Fire execCommand's setTimeout(0) so the handler captures resolveHandler
      await vi.advanceTimersByTimeAsync(1);
      // Well past the (reduced) default timeout — no RequestTimeout must fire
      await vi.advanceTimersByTimeAsync(500);

      expect(resolveHandler).not.toBeNull();
      resolveHandler!();

      await expect(sendPromise).resolves.toEqual({ done: true });
    } finally {
      KM.setDefaultRequestTimeout(10000);
    }
  });

  it('should disable timeout when timeoutMillis is negative', async () => {
    KM.setDefaultRequestTimeout(100);
    try {
      let resolveHandler: (() => void) | null = null;
      KM.browser.addCommand('slowCmd', (_data, resolve) => {
        resolveHandler = () => resolve({ done: true });
      });

      const sendPromise = KM.send('slowCmd', null, -1);

      await vi.advanceTimersByTimeAsync(1);
      await vi.advanceTimersByTimeAsync(500);

      expect(resolveHandler).not.toBeNull();
      resolveHandler!();

      await expect(sendPromise).resolves.toEqual({ done: true });
    } finally {
      KM.setDefaultRequestTimeout(10000);
    }
  });

  it('should fall back to default timeout when timeoutMillis is null', async () => {
    KM.setDefaultRequestTimeout(100);
    try {
      KM.browser.addCommand('slowCmd', () => {
        // Intentionally never resolves
      });

      const promise = KM.send('slowCmd', null, null).catch((e: string) => e);

      await vi.advanceTimersByTimeAsync(1);
      await vi.advanceTimersByTimeAsync(200);

      const error = await promise;
      expect(error).toContain('RequestTimeout');
    } finally {
      KM.setDefaultRequestTimeout(10000);
    }
  });
});

describe('WebPlatform', () => {
  let platform: WebPlatform;

  beforeEach(() => {
    platform = new WebPlatform();
  });

  it('should add and detect a command', () => {
    platform.addCommand('cmd1', vi.fn());
    expect(platform.hasCommand('cmd1')).toBe(true);
  });

  it('should return false for non-existent command', () => {
    expect(platform.hasCommand('nonExistent')).toBe(false);
  });

  it('should remove a command', () => {
    platform.addCommand('cmd1', vi.fn());
    platform.removeCommand('cmd1');
    expect(platform.hasCommand('cmd1')).toBe(false);
  });

  it('should not throw when removing non-existent command', () => {
    expect(() => platform.removeCommand('nonExistent')).not.toThrow();
  });

  it('should support method chaining on addCommand', () => {
    const result = platform.addCommand('a', vi.fn()).addCommand('b', vi.fn());
    expect(result).toBe(platform);
    expect(platform.hasCommand('a')).toBe(true);
    expect(platform.hasCommand('b')).toBe(true);
  });

  it('should support method chaining on removeCommand', () => {
    platform.addCommand('a', vi.fn());
    const result = platform.removeCommand('a');
    expect(result).toBe(platform);
  });

  it('should overwrite an existing command handler', () => {
    platform.addCommand('cmd', vi.fn());
    platform.addCommand('cmd', vi.fn());
    expect(platform.hasCommand('cmd')).toBe(true);
  });
});

describe('uuid', () => {
  it('should generate a valid UUID v4 format', () => {
    const id = uuid();
    expect(id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  });

  it('should generate unique values', () => {
    const ids = new Set(Array.from({ length: 100 }, () => uuid()));
    expect(ids.size).toBe(100);
  });

  it('should always have version 4 indicator at position 14', () => {
    for (let i = 0; i < 10; i++) {
      expect(uuid().charAt(14)).toBe('4');
    }
  });
});

describe('undefinedToNull', () => {
  it('should convert undefined to null', () => {
    expect(undefinedToNull(undefined)).toBeNull();
  });

  it('should preserve null as null', () => {
    expect(undefinedToNull(null)).toBeNull();
  });

  it('should preserve falsy values other than undefined', () => {
    expect(undefinedToNull(0)).toBe(0);
    expect(undefinedToNull('')).toBe('');
    expect(undefinedToNull(false)).toBe(false);
  });

  it('should pass through truthy values unchanged', () => {
    expect(undefinedToNull('hello')).toBe('hello');
    expect(undefinedToNull(42)).toBe(42);
    const obj = { a: 1 };
    expect(undefinedToNull(obj)).toBe(obj);
  });
});
