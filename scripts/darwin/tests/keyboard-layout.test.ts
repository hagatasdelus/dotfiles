import { afterEach, beforeEach, describe, expect, test } from 'bun:test';
import { chmodSync, cpSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import {
  applyResolved,
  currentState,
  listDevices,
  loadConfig,
  resolveState,
  type Config,
  type Device,
  type Resolved,
  type StateFile,
} from '../keyboard-layout';

const REPO_CONFIG = join(
  import.meta.dir,
  '..',
  '..',
  '..',
  'common',
  'config',
  'keyboard-layout',
  'config.json',
);

/** Restore an env var, deleting it when it was unset */
function restore(env: Record<string, string | undefined>, key: string, value: string | undefined): void {
  if (value === undefined) {
    delete env[key];
  } else {
    env[key] = value;
  }
}

function device(partial: Partial<Device> & { vendor_id: number; product_id: number }): Device {  return {
    device_id: `${partial.vendor_id}/${partial.product_id}`,
    product: '',
    manufacturer: '',
    transport: 'usb',
    is_keyboard: true,
    is_built_in: false,
    is_virtual: false,
    country_code: null,
    ...partial,
  };
}

const internalJis = device({
  vendor_id: 1452,
  product_id: 641,
  product: 'Apple Internal Keyboard / Trackpad',
  transport: 'spi',
  is_built_in: true,
  country_code: 15,
});

const homeUs = device({ vendor_id: 12029, product_id: 6514, product: 'Gaming KeyBoard' });

const labJis = device({ vendor_id: 4152, product_id: 6238, product: 'Lab JIS Keyboard' });

const unknownUs = device({ vendor_id: 9999, product_id: 8888, product: 'Mystery Keyboard' });

const virtual = device({
  vendor_id: 1452,
  product_id: 591,
  product: 'Karabiner DriverKit VirtualHIDKeyboard',
  transport: '',
  is_virtual: true,
});

/** Fixture config, independent of the committed config.json */
function testConfig(): Config {
  return {
    default_layout: 'JIS',
    layouts: {
      US: { karabiner_profile: 'US', macskk_key_binding_set: 'AZIK_US', azik_layout: 'us' },
      JIS: { karabiner_profile: 'JIS', macskk_key_binding_set: 'AZIK_JIS', azik_layout: 'jis' },
    },
    devices: [
      { label: 'home US', layout: 'US', match: { vendor_id: 12029, product_id: 6514 } },
      { label: 'lab JIS', layout: 'JIS', match: { vendor_id: 4152, product_id: 6238 } },
      {
        label: 'built-in JIS',
        layout: 'JIS',
        match: { vendor_id: 1452, product_id: 641, is_built_in: true },
      },
    ],
  };
}

function state(partial: Partial<StateFile>): StateFile {
  return {
    version: 1,
    layout: 'US',
    mode: 'auto',
    layout_source: 'rule',
    matched_device: null,
    device_history: [],
    unregistered_devices: [],
    karabiner_profile: 'US',
    macskk_key_binding_set: 'AZIK_US',
    azik_layout: 'us',
    source: 'manual',
    adapters: { karabiner: 'ok', macskk: 'ok' },
    updated_at: '2026-10-14T00:00:00.000Z',
    ...partial,
  };
}

describe('resolveState', () => {
  test('built-in JIS only resolves to JIS', () => {
    const resolved = resolveState(testConfig(), [internalJis], null);

    expect(resolved.layout).toBe('JIS');
    expect(resolved.layout_source).toBe('rule');
    expect(resolved.matched_device?.label).toBe('Apple Internal Keyboard / Trackpad');
  });

  test('built-in JIS + home US resolves to US, ignoring the virtual keyboard', () => {
    const resolved = resolveState(testConfig(), [internalJis, homeUs, virtual], null);

    expect(resolved.layout).toBe('US');
    expect(resolved.layout_source).toBe('rule');
    expect(resolved.unregistered_devices).toHaveLength(0);
  });

  test('unregistered external US keeps JIS and is reported', () => {
    const resolved = resolveState(testConfig(), [unknownUs, internalJis], null);

    expect(resolved.layout).toBe('JIS');
    expect(resolved.unregistered_devices).toHaveLength(1);
    expect(resolved.unregistered_devices[0]?.product).toBe('Mystery Keyboard');
  });

  test('no keyboard at all falls back to default_layout', () => {
    const resolved = resolveState(testConfig(), [], null);

    expect(resolved.layout).toBe('JIS');
    expect(resolved.layout_source).toBe('default');
    expect(resolved.matched_device).toBeNull();
  });

  test('product_contains matches case-insensitively', () => {
    const resolved = resolveState(
      testConfig(),
      [device({ vendor_id: 7, product_id: 7, product: 'KEYCHRON K2' })],
      null,
    );

    expect(resolved.unregistered_devices).toHaveLength(1);
  });

  test('a manual pin is respected', () => {
    const resolved = resolveState(testConfig(), [homeUs, internalJis], state({ layout: 'JIS', mode: 'pinned' }));

    expect(resolved.layout).toBe('JIS');
    expect(resolved.mode).toBe('pinned');
  });

  test('the last attached external device wins (home US, then lab JIS)', () => {
    const previous = state({
      device_history: [
        {
          device_id: '12029/6514',
          vendor_id: 12029,
          product_id: 6514,
          label: 'Gaming KeyBoard',
          transport: 'usb',
          layout: 'US',
        },
      ],
    });

    const resolved = resolveState(testConfig(), [labJis, homeUs, internalJis], previous, 'attach', labJis);

    expect(resolved.layout).toBe('JIS');
    expect(resolved.layout_source).toBe('history');
    expect(resolved.device_history).toHaveLength(2);
    expect(resolved.device_history.at(-1)?.label).toBe('Lab JIS Keyboard');
  });

  test('unplugging the first US keyboard returns to the remaining JIS', () => {
    const previous = state({
      device_history: [
        { device_id: '4152/6238', vendor_id: 4152, product_id: 6238, label: 'Lab JIS Keyboard', transport: 'usb', layout: 'JIS' },
        { device_id: '12029/6514', vendor_id: 12029, product_id: 6514, label: 'Gaming KeyBoard', transport: 'usb', layout: 'US' },
      ],
    });

    const resolved = resolveState(testConfig(), [labJis, internalJis], previous, 'detach');

    expect(resolved.layout).toBe('JIS');
    expect(resolved.layout_source).toBe('history');
    expect(resolved.device_history).toHaveLength(1);
    expect(resolved.device_history[0]?.label).toBe('Lab JIS Keyboard');
  });

  test('an unregistered device never enters the attach history', () => {
    const previous = state({
      device_history: [
        { device_id: '12029/6514', vendor_id: 12029, product_id: 6514, label: 'Gaming KeyBoard', transport: 'usb', layout: 'US' },
      ],
    });

    const resolved = resolveState(testConfig(), [unknownUs, homeUs, internalJis], previous, 'attach', unknownUs);

    expect(resolved.layout).toBe('US');
    expect(resolved.device_history).toHaveLength(1);
    expect(resolved.device_history.at(-1)?.layout).toBe('US');
    expect(resolved.unregistered_devices).toHaveLength(1);
  });

  test('without history the declaration order is used (US declared first)', () => {
    const resolved = resolveState(testConfig(), [labJis, homeUs, internalJis], null);

    expect(resolved.layout).toBe('US');
    expect(resolved.layout_source).toBe('rule');
  });

  test('a built-in appear event changes neither the pin nor the history', () => {
    const resolved = resolveState(
      testConfig(),
      [homeUs, internalJis],
      state({ layout: 'JIS', mode: 'pinned' }),
      'attach',
      internalJis,
    );

    expect(resolved.layout).toBe('JIS');
    expect(resolved.mode).toBe('pinned');
    expect(resolved.device_history).toHaveLength(0);
  });
});

describe('config files', () => {
  let root = '';
  const originalConfigHome = process.env.XDG_CONFIG_HOME;
  const originalStateHome = process.env.XDG_STATE_HOME;
  const originalCli = process.env.KARABINER_CLI;
  const originalMacskk = process.env.MACSKK_SCRIPT;
  const originalWatcher = process.env.KEYBOARD_LAYOUT_WATCHER;

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), 'keyboard-layout-test-'));
    mkdirSync(join(root, 'config', 'keyboard-layout'), { recursive: true });
    mkdirSync(join(root, 'state', 'keyboard-layout'), { recursive: true });
    cpSync(REPO_CONFIG, join(root, 'config', 'keyboard-layout', 'config.json'));
    process.env.XDG_CONFIG_HOME = join(root, 'config');
    process.env.XDG_STATE_HOME = join(root, 'state');

    // Stub Karabiner / macSKK so the tests never touch the live system
    process.env.KEYBOARD_LAYOUT_WATCHER = join(root, 'missing-keyboard-watcher');
    process.env.KARABINER_CLI = join(root, 'karabiner_cli');
    process.env.MACSKK_SCRIPT = join(root, 'macskk-keybinding.sh');
    writeFileSync(
      process.env.KARABINER_CLI,
      '#!/bin/sh\ncase "$1" in --show-current-profile-name) echo "US";; esac\nexit 0\n',
    );
    writeFileSync(process.env.MACSKK_SCRIPT, '#!/bin/sh\nexit 0\n');
    chmodSync(process.env.KARABINER_CLI, 0o755);
    chmodSync(process.env.MACSKK_SCRIPT, 0o755);
  });

  afterEach(() => {
    rmSync(root, { recursive: true, force: true });
    restore(process.env, 'XDG_CONFIG_HOME', originalConfigHome);
    restore(process.env, 'XDG_STATE_HOME', originalStateHome);
    restore(process.env, 'KARABINER_CLI', originalCli);
    restore(process.env, 'MACSKK_SCRIPT', originalMacskk);
    restore(process.env, 'KEYBOARD_LAYOUT_WATCHER', originalWatcher);
  });

  test('config.local.json is merged recursively', async () => {
    writeFileSync(
      join(root, 'config', 'keyboard-layout', 'config.local.json'),
      JSON.stringify({
        default_layout: 'US',
        devices: [{ label: 'built-in US', layout: 'US', match: { is_built_in: true } }],
      }),
    );

    const merged = await loadConfig();

    expect(merged.default_layout).toBe('US');
    expect(merged.devices).toHaveLength(1);
    expect(merged.layouts.JIS).toBeDefined();
  });

  test('the committed config.json maps the home US keyboard to US', async () => {
    const merged = await loadConfig();

    expect(merged.default_layout).toBe('JIS');
    expect(merged.devices[0]?.match.vendor_id).toBe(12029);
    expect(merged.devices[0]?.layout).toBe('US');
  });

  test('dry-run writes no state.json and returns the pinned content', async () => {
    const { state: next } = await applyResolved(
      await loadConfig(),
      {
        layout: 'US',
        mode: 'pinned',
        layout_source: 'pinned',
        matched_device: null,
        device_history: [],
        unregistered_devices: [],
      },
      'manual',
      true,
    );

    expect(next.layout).toBe('US');
    expect(next.mode).toBe('pinned');
    expect(next.karabiner_profile).toBe('US');
    expect(currentState()).toBeNull();
  });

  test('an unchanged state is not rewritten', async () => {
    const resolved = {
      layout: 'US',
      mode: 'auto',
      layout_source: 'rule',
      matched_device: null,
      device_history: [],
      unregistered_devices: [],
    };

    const first = await applyResolved(await loadConfig(), resolved, 'startup', false);
    expect(first.changed).toBe(true);

    // Only source and updated_at differ (the reconcile case)
    const second = await applyResolved(await loadConfig(), resolved, 'reconcile', false);
    expect(second.changed).toBe(false);
  });

  test('a changed adapter status is rewritten', async () => {
    const resolved = {
      layout: 'US',
      mode: 'auto',
      layout_source: 'rule',
      matched_device: null,
      device_history: [],
      unregistered_devices: [],
    };

    writeFileSync(
      join(root, 'state', 'keyboard-layout', 'state.json'),
      JSON.stringify({
        layout: 'US',
        mode: 'auto',
        layout_source: 'rule',
        karabiner_profile: 'US',
        macskk_key_binding_set: 'AZIK_US',
        azik_layout: 'us',
        adapters: { karabiner: 'ok', macskk: 'ok' },
      }),
    );

    const { changed } = await applyResolved(await loadConfig(), resolved, 'reconcile', false);
    expect(changed).toBe(true); // matched_device is null, so the real device data differs
  });

  test('an undefined layout keeps the existing macSKK / azik values', async () => {
    writeFileSync(
      join(root, 'state', 'keyboard-layout', 'state.json'),
      JSON.stringify(state({ layout: 'US', macskk_key_binding_set: 'AZIK_US', azik_layout: 'us' })),
    );

    const merged = await loadConfig();
    delete (merged.layouts as Record<string, unknown>).JIS;

    const { state: next } = await applyResolved(
      merged,
      {
        layout: 'US',
        mode: 'auto',
        layout_source: 'rule',
        matched_device: null,
        device_history: [],
        unregistered_devices: [],
      },
      'manual',
      true,
    );

    expect(next.macskk_key_binding_set).toBe('AZIK_US');
    expect(next.azik_layout).toBe('us');
  });
});

describe('karabiner_cli normalization', () => {
  let root = '';
  const originalCli = process.env.KARABINER_CLI;
  const originalConfigHome = process.env.XDG_CONFIG_HOME;
  const originalWatcher = process.env.KEYBOARD_LAYOUT_WATCHER;

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), 'keyboard-layout-test-'));
    process.env.KARABINER_CLI = join(root, 'karabiner_cli');
    process.env.XDG_CONFIG_HOME = join(root, 'config');
    // Point at a missing path so the real keyboard-watcher is never used
    process.env.KEYBOARD_LAYOUT_WATCHER = join(root, 'missing-keyboard-watcher');
    mkdirSync(join(root, 'config'), { recursive: true });
  });

  afterEach(() => {
    rmSync(root, { recursive: true, force: true });
    if (originalCli === undefined) {
      delete process.env.KARABINER_CLI;
    } else {
      process.env.KARABINER_CLI = originalCli;
    }
    if (originalConfigHome === undefined) {
      delete process.env.XDG_CONFIG_HOME;
    } else {
      process.env.XDG_CONFIG_HOME = originalConfigHome;
    }
    if (originalWatcher === undefined) {
      delete process.env.KEYBOARD_LAYOUT_WATCHER;
    } else {
      process.env.KEYBOARD_LAYOUT_WATCHER = originalWatcher;
    }
  });

  test('reads both device_identifiers and top-level fields', () => {
    const devices = [
      {
        device_identifiers: { is_keyboard: true, vendor_id: 12029, product_id: 6514 },
        manufacturer: 'SONiX',
        product: 'Gaming KeyBoard',
        transport: 'USB',
      },
      {
        device_identifiers: { is_keyboard: true, vendor_id: 1452, product_id: 641 },
        is_apple: true,
        is_built_in_keyboard: true,
        product: 'Apple Internal Keyboard / Trackpad',
        transport: 'SPI',
      },
      {
        device_identifiers: { is_consumer: true },
        product: 'Headset',
        transport: 'Audio',
      },
    ];

    const fake = join(root, 'karabiner_cli');
    writeFileSync(fake, `#!/bin/sh\ncat '${join(root, 'devices.json')}'\n`);
    writeFileSync(join(root, 'devices.json'), JSON.stringify(devices));
    chmodSync(fake, 0o755);

    const normalized = listDevices();

    expect(normalized).toHaveLength(2);
    expect(normalized[0]?.device_id).toBe('12029/6514');
    expect(normalized[0]?.product).toBe('Gaming KeyBoard');
    expect(normalized[1]?.is_built_in).toBe(true);
    expect(normalized[1]?.transport).toBe('spi');
  });
});
