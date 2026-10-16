#!/usr/bin/env bun
/**
 * Karabiner / macSKK / Neovim(skkeleton) keyboard layout switching.
 * State lives only in state.json so reads and writes share a single path.
 */
import { existsSync, readFileSync } from 'node:fs';
import { mkdir, rename, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';

interface DeviceMatch {
    vendor_id?: number | null;
    product_id?: number | null;
    country_code?: number | null;
    transport?: string | null;
    is_built_in?: boolean | null;
    product_contains?: string | null;
}

interface DeviceRule {
    label?: string;
    layout: string;
    match: DeviceMatch;
    note?: string;
}

interface LayoutSetting {
    label?: string;
    karabiner_profile: string;
    macskk_key_binding_set: string;
    azik_layout: string;
}

interface Config {
    default_layout: string;
    layouts: Record<string, LayoutSetting>;
    devices: DeviceRule[];
}

interface Device {
    device_id: string;
    vendor_id: number | null;
    product_id: number | null;
    product: string;
    manufacturer: string;
    transport: string;
    is_keyboard: boolean;
    is_built_in: boolean;
    is_virtual: boolean;
    country_code: number | null;
}

interface HistoryEntry {
    device_id: string;
    vendor_id: number | null;
    product_id: number | null;
    label: string;
    transport: string;
    layout: string;
}

interface MatchedDevice {
    device_id: string;
    vendor_id: number | null;
    product_id: number | null;
    label: string;
    transport: string;
}

interface UnregisteredDevice {
    vendor_id: number | null;
    product_id: number | null;
    product: string;
    manufacturer: string;
    transport: string;
}

type LayoutSource = 'pinned' | 'history' | 'rule' | 'default';

interface Resolved {
    layout: string;
    mode: 'auto' | 'pinned';
    layout_source: LayoutSource;
    matched_device: MatchedDevice | null;
    device_history: HistoryEntry[];
    unregistered_devices: UnregisteredDevice[];
}

interface StateFile extends Resolved {
    version: number;
    karabiner_profile: string;
    macskk_key_binding_set: string;
    azik_layout: string;
    source: string;
    adapters: { karabiner: string; macskk: string };
    updated_at: string;
}

interface Paths {
    dotfiles: string;
    configFile: string;
    configLocalFile: string;
    stateDir: string;
    stateFile: string;
    watcherBin: string;
    karabinerCli: string;
    macskkScript: string;
}

export type {
    Config,
    Device,
    DeviceMatch,
    DeviceRule,
    HistoryEntry,
    LayoutSetting,
    LayoutSource,
    MatchedDevice,
    Paths,
    Resolved,
    StateFile,
    UnregisteredDevice,
};

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function optionalString(value: unknown, fallback = ''): string {
    return typeof value === 'string' ? value : fallback;
}

function optionalNumber(value: unknown): number | null {
    return typeof value === 'number' ? value : null;
}

function optionalBool(value: unknown, fallback = false): boolean {
    return typeof value === 'boolean' ? value : fallback;
}

function die(message: string): never {
    console.error(`keyboard-layout: ${message}`);
    process.exit(1);
}

function run(command: string[], input?: string) {
    const result = Bun.spawnSync(command, {
        stdin: input === undefined ? 'ignore' : 'pipe',
        stdout: 'pipe',
        stderr: 'pipe',
    });
    return {
        code: result.exitCode,
        stdout: result.stdout ? new TextDecoder().decode(result.stdout) : '',
        stderr: result.stderr ? new TextDecoder().decode(result.stderr) : '',
    };
}

function notify(message: string): void {
    run([
        'osascript',
        '-e',
        `display notification "${message.replace(/"/g, '\\"')}" with title "Keyboard Layout"`,
    ]);
}

function pathExists(path: string): boolean {
    return existsSync(path);
}

function deviceIdOf(vendorId: number | null, productId: number | null): string {
    return `${vendorId ?? -1}/${productId ?? -1}`;
}

function paths(): Paths {
    const home = homedir();
    const dotfiles = process.env.DOTFILES_DIR ?? join(home, 'ghq/github.com/hagatasdelus/dotfiles');
    const xdgConfig = process.env.XDG_CONFIG_HOME ?? join(home, '.config');
    const xdgState = process.env.XDG_STATE_HOME ?? join(home, '.local/state');

    return {
        dotfiles,
        configFile: join(xdgConfig, 'keyboard-layout', 'config.json'),
        configLocalFile: join(xdgConfig, 'keyboard-layout', 'config.local.json'),
        stateDir: join(xdgState, 'keyboard-layout'),
        stateFile: join(xdgState, 'keyboard-layout', 'state.json'),
        watcherBin:
            process.env.KEYBOARD_LAYOUT_WATCHER ?? join(dotfiles, 'scripts/darwin/bin/keyboard-watcher'),
        karabinerCli:
            process.env.KARABINER_CLI ??
            '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli',
        macskkScript: process.env.MACSKK_SCRIPT ?? join(dotfiles, 'scripts/darwin/macskk-keybinding.sh'),
    };
}

function deepMerge(base: unknown, local: unknown): unknown {
    if (!isRecord(base) || !isRecord(local)) {
        return local;
    }

    const merged: Record<string, unknown> = { ...base };
    for (const [key, value] of Object.entries(local)) {
        merged[key] = key in base ? deepMerge(base[key], value) : value;
    }
    return merged;
}

function validateConfig(value: unknown): Config {
    const record = isRecord(value) ? value : {};
    const layouts = isRecord(record.layouts) ? record.layouts : {};
    const devices = Array.isArray(record.devices) ? record.devices : [];
    const defaultLayout = optionalString(record.default_layout);

    if (defaultLayout === '' || Object.keys(layouts).length === 0) {
        die('invalid config: default_layout and layouts are required');
    }
    if (!(defaultLayout in layouts)) {
        die(`invalid config: default_layout "${defaultLayout}" is not in layouts`);
    }

    return {
        default_layout: defaultLayout,
        layouts: layouts as Record<string, LayoutSetting>,
        devices: devices as DeviceRule[],
    };
}

export function loadConfig(): Config {
    const p = paths();
    if (!pathExists(p.configFile)) {
        die(`config not found: ${p.configFile}`);
    }

    const read = (path: string, label: string): unknown => {
        try {
            return JSON.parse(readFileSync(path, 'utf8'));
        } catch (error) {
            die(`invalid config json: ${label} (${error})`);
        }
    };

    let merged = read(p.configFile, p.configFile);
    if (pathExists(p.configLocalFile)) {
        merged = deepMerge(merged, read(p.configLocalFile, p.configLocalFile));
    }

    return validateConfig(merged);
}

function normalizeDevice(raw: Record<string, unknown>): Device {
    const identifiers = isRecord(raw.device_identifiers) ? raw.device_identifiers : raw;
    const vendorId = optionalNumber(identifiers.vendor_id);
    const productId = optionalNumber(identifiers.product_id);
    const transport = optionalString(raw.transport).toLowerCase();

    return {
        device_id: deviceIdOf(vendorId, productId),
        vendor_id: vendorId,
        product_id: productId,
        product: optionalString(raw.product),
        manufacturer: optionalString(raw.manufacturer),
        transport,
        is_keyboard: optionalBool(identifiers.is_keyboard),
        is_built_in: optionalBool(raw.is_built_in, optionalBool(raw.is_built_in_keyboard)),
        is_virtual: optionalBool(identifiers.is_virtual_device) || transport === '',
        country_code: optionalNumber(raw.country_code),
    };
}

export function listDevices(): Device[] {
    const p = paths();

    if (pathExists(p.watcherBin)) {
        const watcher = run([p.watcherBin, 'list']);
        if (watcher.code === 0) {
            try {
                const parsed = JSON.parse(watcher.stdout);
                const devices = isRecord(parsed) && Array.isArray(parsed.devices) ? parsed.devices : [];
                return devices.map((device) => normalizeDevice(isRecord(device) ? device : {}));
            } catch {
                // Fall back to karabiner_cli if the watcher is broken
            }
        }
    }

    const karabiner = run([p.karabinerCli, '--list-connected-devices']);
    if (karabiner.code !== 0) {
        die(`no device source: both keyboard-watcher and karabiner_cli failed\n${karabiner.stderr}`);
    }

    try {
        const parsed = JSON.parse(karabiner.stdout);
        return (Array.isArray(parsed) ? parsed : [])
            .map((device) => normalizeDevice(isRecord(device) ? device : {}))
            .filter((device) => device.is_keyboard);
    } catch (error) {
        die(`cannot parse karabiner_cli output: ${error}`);
    }
}

export function currentState(): StateFile | null {
    const p = paths();
    if (!pathExists(p.stateFile)) {
        return null;
    }

    try {
        const state = JSON.parse(readFileSync(p.stateFile, 'utf8'));
        return isRecord(state) ? (state as unknown as StateFile) : null;
    } catch {
        return null;
    }
}

// Resolution (pure)

function isExternal(device: Device): boolean {
    return !device.is_built_in && (device.transport === 'usb' || device.transport === 'bluetooth');
}

function matchesMatch(device: Device, match: DeviceMatch): boolean {
    if (match.vendor_id != null && device.vendor_id !== match.vendor_id) {
        return false;
    }
    if (match.product_id != null && device.product_id !== match.product_id) {
        return false;
    }
    if (match.country_code != null && device.country_code !== match.country_code) {
        return false;
    }
    if (match.transport != null && device.transport !== match.transport.toLowerCase()) {
        return false;
    }
    if (match.is_built_in != null && device.is_built_in !== match.is_built_in) {
        return false;
    }
    if (match.product_contains != null) {
        const name = device.product.toLowerCase();
        if (!name.includes(match.product_contains.toLowerCase())) {
            return false;
        }
    }
    return true;
}

function ruleFor(device: Device, config: Config): DeviceRule | null {
    return config.devices.find((rule) => matchesMatch(device, rule.match ?? {})) ?? null;
}

/** Only external registered devices enter the attach history */
function registeredExternalDevices(config: Config, devices: Device[]): (Device & { rule: DeviceRule })[] {
    return devices
        .filter((device) => device.is_keyboard && !device.is_virtual && isExternal(device))
        .map((device) => ({ ...device, rule: ruleFor(device, config) }))
        .filter((device): device is Device & { rule: DeviceRule } => device.rule !== null);
}

function toHistoryEntry(device: Device, rule: DeviceRule): HistoryEntry {
    return {
        device_id: device.device_id,
        vendor_id: device.vendor_id,
        product_id: device.product_id,
        label: device.product,
        transport: device.transport,
        layout: rule.layout,
    };
}

function toMatchedDevice(device: Device): MatchedDevice {
    return {
        device_id: device.device_id,
        vendor_id: device.vendor_id,
        product_id: device.product_id,
        label: device.product,
        transport: device.transport,
    };
}

/**
 * No side effects. Order: pinned > last attached external > declaration order > default.
 * macOS exposes no attach timestamp, so "last attached" comes from state.json.
 */
export function resolveState(
    config: Config,
    devices: Device[],
    state: StateFile | null,
    event = '',
    hint: Device | null = null,
): Resolved {
    const keyboards = devices.filter((device) => device.is_keyboard && !device.is_virtual);
    const external = registeredExternalDevices(config, keyboards);

    // Built-in keyboards can appear on their own (SPI), and are never "plugged in"
    const meaningfulEvent = event !== '' && (hint === null || isExternal(hint));

    const attached =
        meaningfulEvent && hint !== null
            ? (external.find((candidate) => candidate.device_id === hint.device_id) ?? null)
            : null;
    let history = (state?.device_history ?? []).filter((entry) =>
        external.some((device) => device.device_id === entry.device_id),
    );

    if (meaningfulEvent && event === 'attach' && attached) {
        const entry = toHistoryEntry(attached, attached.rule);
        history = [...history.filter((item) => item.device_id !== entry.device_id), entry];
    }

    // An external event releases a manual pin
    const mode = meaningfulEvent ? 'auto' : (state?.mode ?? 'auto');

    if (mode === 'pinned') {
        return {
            layout: state?.layout ?? config.default_layout,
            mode,
            layout_source: 'pinned',
            matched_device: null,
            device_history: history,
            unregistered_devices: unregisteredDevices(keyboards, config),
        };
    }

    if (history.length > 0) {
        const last = history[history.length - 1]!;
        return {
            layout: last.layout,
            mode,
            layout_source: 'history',
            matched_device: {
                device_id: last.device_id,
                vendor_id: last.vendor_id,
                product_id: last.product_id,
                label: last.label,
                transport: last.transport,
            },
            device_history: history,
            unregistered_devices: unregisteredDevices(keyboards, config),
        };
    }

    for (const rule of config.devices) {
        const device = keyboards.find((candidate) => matchesMatch(candidate, rule.match ?? {}));
        if (device) {
            return {
                layout: rule.layout,
                mode,
                layout_source: 'rule',
                matched_device: toMatchedDevice(device),
                device_history: history,
                unregistered_devices: unregisteredDevices(keyboards, config),
            };
        }
    }

    return {
        layout: config.default_layout,
        mode,
        layout_source: 'default',
        matched_device: null,
        device_history: history,
        unregistered_devices: unregisteredDevices(keyboards, config),
    };
}

function unregisteredDevices(keyboards: Device[], config: Config): UnregisteredDevice[] {
    return keyboards
        .filter((device) => isExternal(device) && ruleFor(device, config) === null)
        .map((device) => ({
            vendor_id: device.vendor_id,
            product_id: device.product_id,
            product: device.product,
            manufacturer: device.manufacturer,
            transport: device.transport,
        }));
}

function otherLayout(config: Config, current: string): string {
    return Object.keys(config.layouts).find((layout) => layout !== current) ?? current;
}

// Adapters (side effects)

function applyKarabiner(profile: string): string {
    const p = paths();
    if (profile === '') {
        return 'skipped';
    }
    if (!pathExists(p.karabinerCli)) {
        return 'missing';
    }

    const current = run([p.karabinerCli, '--show-current-profile-name']).stdout.trim();
    if (current === profile) {
        return 'ok';
    }

    const result = run([p.karabinerCli, '--select-profile', profile]);
    return result.code === 0 ? `switched:${current}->${profile}` : 'failed';
}

function applyMacskk(keyBindingSet: string): string {
    const p = paths();
    if (keyBindingSet === '') {
        return 'skipped';
    }
    if (!pathExists(p.macskkScript)) {
        return 'missing';
    }

    const result = run([p.macskkScript, keyBindingSet]);
    return result.code === 0 ? 'ok' : 'failed';
}

function layoutSettings(config: Config, layout: string): LayoutSetting | null {
    return config.layouts[layout] ?? null;
}

async function writeState(
    resolved: Resolved,
    setting: { profile: string; macskk: string; azik: string },
    source: string,
    adapters: { karabiner: string; macskk: string },
): Promise<void> {
    const p = paths();
    await mkdir(p.stateDir, { recursive: true });

    const state: StateFile = {
        version: 1,
        ...resolved,
        karabiner_profile: setting.profile,
        macskk_key_binding_set: setting.macskk,
        azik_layout: setting.azik,
        source,
        adapters,
        updated_at: new Date().toISOString(),
    };

    const temporary = join(p.stateDir, `.state.json.tmp.${process.pid}`);
    await writeFile(temporary, `${JSON.stringify(state, null, 2)}\n`);
    await rename(temporary, p.stateFile);
}

/** dryRun applies nothing. Unchanged state writes nothing and notifies nothing */
export async function applyResolved(
    config: Config,
    resolved: Resolved,
    source: string,
    dryRun: boolean,
): Promise<{ state: StateFile; changed: boolean }> {
    const setting = layoutSettings(config, resolved.layout);
    const state = currentState();

    // Keep previous values when the layout is unknown
    const target = {
        profile: setting?.karabiner_profile ?? state?.karabiner_profile ?? '',
        macskk: setting?.macskk_key_binding_set ?? state?.macskk_key_binding_set ?? '',
        azik: setting?.azik_layout ?? state?.azik_layout ?? 'us',
    };

    const karabiner = dryRun ? 'dry-run' : applyKarabiner(target.profile);
    const macskk = dryRun ? 'dry-run' : applyMacskk(target.macskk);

    const next: StateFile = {
        version: 1,
        ...resolved,
        karabiner_profile: target.profile,
        macskk_key_binding_set: target.macskk,
        azik_layout: target.azik,
        source,
        adapters: { karabiner, macskk },
        updated_at: new Date().toISOString(),
    };

    if (dryRun) {
        return { state: next, changed: true };
    }

    const changed = state === null || stateFingerprint(state) !== stateFingerprint(next);
    if (changed) {
        await writeState(resolved, target, source, { karabiner, macskk });
    }

    return { state: next, changed };
}

function report(state: StateFile, changed: boolean, dryRun: boolean, message: string): void {
    if (dryRun) {
        console.log(state.layout);
        return;
    }

    if (!changed) {
        console.log(`no change: ${state.layout}`);
        return;
    }

    if (state.unregistered_devices.length > 0) {
        const names = state.unregistered_devices
            .map((device) => `${device.product} [${device.vendor_id}/${device.product_id}]`)
            .join(', ');
        notify(`${names} is unregistered; keeping the default layout`);
    }

    notify(message);
    console.log(message);
}

/** source and updated_at are excluded: they change on every reconcile */
function stateFingerprint(state: StateFile): string {
    return JSON.stringify({
        layout: state.layout,
        mode: state.mode,
        layout_source: state.layout_source,
        karabiner_profile: state.karabiner_profile,
        macskk_key_binding_set: state.macskk_key_binding_set,
        azik_layout: state.azik_layout,
        matched_device: state.matched_device,
        device_history: state.device_history,
        unregistered_devices: state.unregistered_devices,
        adapters: state.adapters,
    });
}

function describeDevice(device: MatchedDevice | null): string {
    return device === null ? '—' : `${device.label} [${device.vendor_id}/${device.product_id}]`;
}

/** Bun has no isTTY, so use /bin/sh test -t */
function isInteractive(): boolean {
    const result = Bun.spawnSync(['/bin/sh', '-c', 'test -t 0'], {
        stdin: 'inherit',
        stdout: 'ignore',
        stderr: 'ignore',
    });
    return result.exitCode === 0;
}

// Commands

interface Options {
    dryRun: boolean;
    json: boolean;
    event: string;
    hint: Device | null;
    source: string;
    positional: string[];
}

function parseOptions(argv: string[]): Options {
    const options: Options = {
        dryRun: false,
        json: false,
        event: '',
        hint: null,
        source: 'manual',
        positional: [],
    };

    for (let index = 0; index < argv.length; index += 1) {
        const argument = argv[index]!;

        if (argument === '--dry-run') {
            options.dryRun = true;
        } else if (argument === '--json') {
            options.json = true;
        } else if (argument === '--event') {
            index += 1;
            options.event = argv[index] ?? '';
        } else if (argument === '--hint') {
            index += 1;
            try {
                options.hint = normalizeDevice(JSON.parse(argv[index] ?? '{}'));
            } catch (error) {
                die(`cannot parse --hint JSON: ${error}`);
            }
        } else if (argument === '--source') {
            index += 1;
            options.source = argv[index] ?? 'manual';
        } else {
            options.positional.push(argument);
        }
    }

    return options;
}

async function resolveCommand(options: Options): Promise<void> {
    const config = loadConfig();
    const resolved = resolveState(config, listDevices(), currentState(), options.event, options.hint);

    if (options.json) {
        console.log(JSON.stringify(resolved, null, 2));
        return;
    }

    const history =
        resolved.device_history.length === 0
            ? '—'
            : resolved.device_history.map((entry) => `${entry.label} -> ${entry.layout}`).join(' ← ');

    console.log(`layout:        ${resolved.layout} (${resolved.mode}, ${resolved.layout_source})`);
    console.log(`device:        ${describeDevice(resolved.matched_device)}`);
    console.log(`history:       ${history}`);
    console.log(
        `unregistered:  ${resolved.unregistered_devices.length === 0
            ? '—'
            : resolved.unregistered_devices
                .map((device) => `${device.product} [${device.vendor_id}/${device.product_id}]`)
                .join(', ')
        }`,
    );
}

function statusCommand(): void {
    const state = currentState();
    if (state === null) {
        console.log('state: none');
    } else {
        console.log(
            `state: ${state.layout} [${state.mode}] karabiner=${state.karabiner_profile} ` +
            `macSKK=${state.macskk_key_binding_set} azik=${state.azik_layout}`,
        );
        console.log(
            `       source=${state.source} device=${describeDevice(state.matched_device)} ` +
            `adapters=${state.adapters.karabiner}/${state.adapters.macskk} updated=${state.updated_at}`,
        );
    }

    const config = loadConfig();
    const resolved = resolveState(config, listDevices(), currentState());
    console.log(
        `now:   ${resolved.layout} [${resolved.layout_source}] unregistered=${resolved.unregistered_devices.length}`,
    );
}

async function syncCommand(options: Options): Promise<void> {
    const config = loadConfig();
    const resolved = resolveState(config, listDevices(), currentState(), options.event, options.hint);
    const { state, changed } = await applyResolved(config, resolved, options.source, options.dryRun);

    if (options.json) {
        console.log(JSON.stringify(state, null, 2));
        return;
    }

    report(state, changed, options.dryRun, `Synced: ${state.layout}`);
}

async function pinCommand(config: Config, layout: string, options: Options): Promise<void> {
    const resolved = resolveState(config, listDevices(), currentState(), options.event, options.hint);
    const pinned: Resolved = { ...resolved, layout, mode: 'pinned', layout_source: 'pinned' };
    const { state, changed } = await applyResolved(config, pinned, options.source, options.dryRun);

    if (options.json) {
        console.log(JSON.stringify(state, null, 2));
        return;
    }

    report(state, changed, options.dryRun, `Keyboard Layout: ${layout}`);
}

async function toggleCommand(options: Options): Promise<void> {
    const config = loadConfig();
    const resolved = resolveState(config, listDevices(), currentState(), options.event, options.hint);
    await pinCommand(config, otherLayout(config, resolved.layout), options);
}

async function setCommand(options: Options): Promise<void> {
    const layout = options.positional[0];
    if (layout === undefined || layout === '') {
        die('usage: keyboard-layout set <LAYOUT>');
    }

    const config = loadConfig();
    if (!(layout in config.layouts)) {
        die(`unknown layout: ${layout} (${Object.keys(config.layouts).join(' ')})`);
    }

    await pinCommand(config, layout, options);
}

async function autoCommand(options: Options): Promise<void> {
    const config = loadConfig();

    // Re-resolve as auto so layout_source / matched_device stay accurate
    const previous = currentState();
    const forced = previous === null ? null : { ...previous, mode: 'auto' as const };
    const resolved = resolveState(config, listDevices(), forced, options.event, options.hint);

    const { state, changed } = await applyResolved(config, resolved, options.source, options.dryRun);

    if (options.json) {
        console.log(JSON.stringify(state, null, 2));
        return;
    }

    report(state, changed, options.dryRun, 'Auto: follow devices');
}

async function selectCommand(options: Options): Promise<void> {
    const config = loadConfig();
    const p = paths();

    if (!isInteractive()) {
        die('select requires a TTY (run it from a terminal or a herdr popup)');
    }

    const current = currentState()?.karabiner_profile ?? '';
    const profiles = run([p.karabinerCli, '--list-profile-names']).stdout.trim();
    const choices = profiles.split('\n').filter((line) => line !== '');

    const fzf = Bun.spawn(
        [
            'fzf',
            '--prompt',
            'Karabiner Profile > ',
            '--height',
            '10',
            '--layout',
            'reverse',
            '--header',
            `Select profile (Current: ${current}):`,
        ],
        { stdin: 'pipe', stdout: 'pipe', stderr: 'inherit' },
    );

    fzf.stdin.write(`${choices.join('\n')}\n`);
    await fzf.stdin.end();
    const choice = (await new Response(fzf.stdout).text()).trim();
    await fzf.exited;

    if (choice === '') {
        console.log('Cancelled.');
        return;
    }

    if (choice in config.layouts) {
        await pinCommand(config, choice, options);
        return;
    }

    // Unknown profile: switch Karabiner only, keep macSKK / Neovim as-is
    const state = currentState();
    const resolved = resolveState(config, listDevices(), state);
    const karabiner = applyKarabiner(choice);

    const next: StateFile = {
        version: 1,
        ...resolved,
        karabiner_profile: choice,
        macskk_key_binding_set: state?.macskk_key_binding_set ?? '',
        azik_layout: state?.azik_layout ?? 'us',
        source: options.source,
        adapters: { karabiner, macskk: 'kept' },
        updated_at: new Date().toISOString(),
    };

    const changed = state === null || stateFingerprint(state) !== stateFingerprint(next);
    if (!options.dryRun && changed) {
        await writeState(resolved, {
            profile: choice,
            macskk: next.macskk_key_binding_set,
            azik: next.azik_layout,
        }, options.source, next.adapters);
    }

    notify(`Karabiner profile: ${choice}`);
    console.log(
        `Karabiner profile: ${choice} (layout not defined; macSKK / Neovim left as-is)`,
    );
}

async function runCommand(options: Options): Promise<void> {
    console.log('keyboard-layout: polling mode (2s). Ctrl-C to stop.');
    while (true) {
        const config = loadConfig();
        const resolved = resolveState(config, listDevices(), currentState(), '', null);
        await applyResolved(config, resolved, 'poll', false);
        await Bun.sleep(2000);
    }
}

function usage(): void {
    console.log(`keyboard-layout - Karabiner / macSKK / Neovim(skkeleton) keyboard layout switching

usage: keyboard-layout <command> [options]

commands:
  resolve             Resolve the layout from connected devices (no side effects)
  status              Show the current state
  sync                Resolve -> apply -> write state.json
  set LAYOUT          Pin a layout manually
  toggle              Flip US/JIS (pinned)
  auto                Release the pin and follow devices
  select              Pick a Karabiner profile with fzf
  run                 Polling loop for hosts without the daemon

options:
  --dry-run           Apply nothing, only report
  --json              Print the state.json equivalent as JSON
  --event attach|detach  Tell the CLI which device changed
  --hint JSON         JSON of the attached device
  --source NAME       Reason recorded in state.json`);
}

async function main(): Promise<void> {
    const [command, ...rest] = process.argv.slice(2);
    const options = parseOptions(rest);
    options.source = options.source ?? 'manual';

    switch (command) {
        case 'resolve':
            await resolveCommand(options);
            break;
        case 'status':
            statusCommand();
            break;
        case 'sync':
            await syncCommand(options);
            break;
        case 'set':
            await setCommand(options);
            break;
        case 'toggle':
            await toggleCommand(options);
            break;
        case 'auto':
            await autoCommand(options);
            break;
        case 'select':
            await selectCommand(options);
            break;
        case 'run':
            await runCommand(options);
            break;
        default:
            usage();
            if (command !== undefined && command !== 'help' && command !== '--help') {
                die(`unknown command: ${command}`);
            }
    }
}

if (import.meta.main) {
    await main();
}
