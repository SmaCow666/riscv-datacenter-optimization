#!/usr/bin/env python3
"""Measure RISC-V-hosted QEMU startup and optionally gate/measure a Linux or bare-metal guest."""
import argparse
import csv
import hashlib
import json
import os
import platform
import selectors
import shutil
import socket
import statistics
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROTOCOL = json.loads((HERE / 'protocol.json').read_text(encoding='utf-8'))


def need(ok, message):
    if not ok:
        raise ValueError(message)


def sha256(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def save(path, data):
    Path(path).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def elf_machine(path):
    with Path(path).open('rb') as f:
        header = f.read(20)
    need(len(header) == 20 and header[:4] == b'\x7fELF' and header[4] == 2 and header[5] == 1,
         f'Expected ELF64 little-endian QEMU executable: {path}')
    machine = int.from_bytes(header[18:20], 'little')
    need(machine == 243, f'Expected RISC-V ELF (e_machine=243): {path}')
    need(os.access(path, os.X_OK), f'QEMU binary is not executable: {path}')
    return machine


def qmp_line(proc, selector, buffer, deadline):
    while b'\n' not in buffer:
        remaining = deadline - time.monotonic()
        need(remaining > 0, 'Timed out waiting for QMP output')
        events = selector.select(remaining)
        need(events, 'Timed out waiting for QMP output')
        data = os.read(proc.stdout.fileno(), 65536)
        need(data, 'QEMU closed its QMP output')
        buffer += data
        need(len(buffer) <= 16 * 1024 * 1024, 'QMP response exceeded 16 MiB')
    line, buffer = buffer.split(b'\n', 1)
    return json.loads(line), buffer


def qmp_exchange(proc, selector, buffer, message_id, command, arguments=None, timeout=20):
    request = {'execute': command, 'id': message_id}
    if arguments is not None:
        request['arguments'] = arguments
    proc.stdin.write((json.dumps(request) + '\r\n').encode())
    proc.stdin.flush()
    deadline = time.monotonic() + timeout
    events = []
    while True:
        reply, buffer = qmp_line(proc, selector, buffer, deadline)
        if 'event' in reply:
            events.append(reply)
            continue
        if reply.get('id') != message_id:
            continue
        need('error' not in reply, f'QMP {command} failed: {reply.get("error")}')
        need('return' in reply, f'QMP {command} returned no result')
        return reply['return'], buffer, events


def base_args(binary, vcpus, memory, cpu):
    thread = 'single' if vcpus == 1 else 'multi'
    return [str(binary), '-machine', 'virt', '-accel', 'tcg,thread=' + thread,
            '-cpu', cpu, '-m', memory, '-smp', str(vcpus), '-bios', 'none',
            '-display', 'none', '-monitor', 'none', '-nic', 'none', '-no-reboot']


def qmp_probe(binary, vcpus, memory, cpu, timeout):
    command = base_args(binary, vcpus, memory, cpu) + ['-serial', 'none', '-S', '-qmp', 'stdio']
    stderr = tempfile.TemporaryFile()
    proc = None
    selector = selectors.DefaultSelector()
    started = time.monotonic_ns()
    transcript = []
    try:
        proc = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                stderr=stderr, bufsize=0, start_new_session=True)
        selector.register(proc.stdout, selectors.EVENT_READ)
        buffer = b''
        greeting, buffer = qmp_line(proc, selector, buffer, time.monotonic() + timeout)
        ready = time.monotonic_ns()
        need('QMP' in greeting, 'QEMU did not send a QMP greeting')
        transcript.append(greeting)
        _, buffer, events = qmp_exchange(proc, selector, buffer, 'caps', 'qmp_capabilities', timeout=timeout)
        transcript.extend(events)
        status, buffer, events = qmp_exchange(proc, selector, buffer, 'status', 'query-status', timeout=timeout)
        transcript.extend(events)
        need(status.get('running') is False, 'QEMU did not remain paused at prelaunch')
        machines, buffer, events = qmp_exchange(proc, selector, buffer, 'machines', 'query-machines', timeout=timeout)
        transcript.extend(events)
        types, buffer, events = qmp_exchange(proc, selector, buffer, 'device-types', 'qom-list-types',
                                             {'implements': 'device', 'abstract': True}, timeout)
        transcript.extend(events)
        machine_names = sorted(item.get('name', '') for item in machines)
        device_types = sorted(item.get('name', '') for item in types)
        need('virt' in machine_names, 'QMP machine list does not contain the virt machine')
        need(device_types, 'QMP returned no QOM device classes')
        proc.stdin.write(b'{"execute":"quit","id":"quit"}\r\n')
        proc.stdin.flush()
        proc.wait(timeout=timeout)
        need(proc.returncode == 0, f'QEMU exited with status {proc.returncode}')
        stderr.seek(0)
        return {'elapsed_ns': ready - started, 'command': command, 'qmp_greeting': greeting,
                'status': status, 'machine_names': machine_names, 'device_type_count': len(device_types),
                'device_types_sha256': hashlib.sha256('\n'.join(device_types).encode()).hexdigest(),
                'qmp_transcript': transcript, 'stderr': stderr.read().decode(errors='replace')}
    finally:
        if proc is not None and proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        selector.close()
        stderr.close()


def guest_boot(binary, vcpus, memory, cpu, kernel, initrd, append, pass_marker, fail_marker, timeout):
    command = base_args(binary, vcpus, memory, cpu) + [
        '-serial', 'stdio', '-kernel', str(kernel), '-initrd', str(initrd), '-append', append]
    stderr = tempfile.TemporaryFile()
    proc = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=stderr, bufsize=0, start_new_session=True)
    selector = selectors.DefaultSelector()
    selector.register(proc.stdout, selectors.EVENT_READ)
    started = time.monotonic_ns()
    output = bytearray()
    try:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            events = selector.select(max(0, min(1, deadline - time.monotonic())))
            if not events:
                if proc.poll() is not None:
                    break
                continue
            data = os.read(proc.stdout.fileno(), 65536)
            if not data:
                break
            output.extend(data)
            need(len(output) <= 32 * 1024 * 1024, 'Guest serial output exceeded 32 MiB')
            text = output.decode(errors='replace')
            need(fail_marker not in text, f'Guest reported failure marker {fail_marker!r}')
            if pass_marker in text:
                return {'elapsed_ns': time.monotonic_ns() - started, 'command': command,
                        'marker': pass_marker, 'serial_sha256': hashlib.sha256(output).hexdigest(),
                        'serial_tail': text[-4096:]}
        raise TimeoutError(f'Guest did not emit success marker {pass_marker!r} within {timeout}s')
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        selector.close()
        stderr.seek(0)
        (HERE / '__unused__') if False else None
        stderr.close()


def guest_line_step(line, stage, expected_checksum):
    """Advance the RVWORK handshake state machine by one serial line.

    line is stripped decoded text. Returns (stage, reply) where reply is a
    bytes payload to send or None. Raises ValueError on guest failure or on a
    checksum that differs from the expected value.
    """
    need('FAIL' not in line, 'Guest reported failure')
    if stage == 0 and line == 'RVWORK_READY':
        return 1, b'g\n'
    if stage == 1 and line.startswith('RVWORK_DONE '):
        checksum = line[len('RVWORK_DONE '):].strip()
        need(checksum == expected_checksum,
             f'Guest checksum {checksum!r} differs from expected {expected_checksum!r}')
        return 2, b'e\n'
    return stage, None


def guest_elf_boot(binary, vcpus, memory, cpu, elf, expected_checksum, timeout):
    """Run a bare-metal guest through the RVWORK serial handshake.

    Guest prints RVWORK_READY, waits for 'g', runs the workload, prints
    RVWORK_DONE <8-hex checksum>, waits for 'e' and exits 0. The observed
    checksum must equal the expected one on both arms.
    """
    command = base_args(binary, vcpus, memory, cpu) + ['-kernel', str(elf), '-serial', 'stdio']
    stderr = tempfile.TemporaryFile()
    proc = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=stderr, bufsize=0, start_new_session=True)
    selector = selectors.DefaultSelector()
    selector.register(proc.stdout, selectors.EVENT_READ)
    started = time.monotonic_ns()
    buffer = bytearray()
    full = bytearray()
    stage = 0
    transcript = []
    elapsed = None
    checksum = None
    try:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            events = selector.select(max(0, min(1, deadline - time.monotonic())))
            if not events:
                if proc.poll() is not None:
                    break
                continue
            data = os.read(proc.stdout.fileno(), 65536)
            if not data:
                break
            buffer.extend(data)
            full.extend(data)
            need(len(full) <= 32 * 1024 * 1024, 'Guest serial output exceeded 32 MiB')
            while b'\n' in buffer:
                line, _, buffer = buffer.partition(b'\n')
                line = line.strip()
                if not line:
                    continue
                transcript.append(line.decode(errors='replace'))
                previous = stage
                stage, reply = guest_line_step(line.decode(errors='replace'), stage, expected_checksum)
                if reply is not None:
                    proc.stdin.write(reply)
                    proc.stdin.flush()
                if stage == 2 and previous == 1:
                    checksum = line[len(b'RVWORK_DONE '):].decode(errors='replace').strip()
                    elapsed = time.monotonic_ns() - started
            if stage == 2 and proc.poll() is not None:
                break
        need(stage == 2, 'Guest did not complete the RVWORK handshake within the timeout')
        if proc.poll() is None:
            proc.wait(timeout=timeout)
        need(proc.returncode == 0, f'Guest exited with status {proc.returncode}')
        return {'elapsed_ns': elapsed, 'command': command, 'checksum': checksum,
                'transcript': transcript, 'serial_sha256': hashlib.sha256(full).hexdigest(),
                'serial_tail': full.decode(errors='replace')[-4096:]}
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        selector.close()
        stderr.seek(0)
        stderr.close()


def order_for_block(index):
    return PROTOCOL['orders'][index % len(PROTOCOL['orders'])]


def median_summary(rows, vcpus, scenario):
    selected = [row for row in rows if row['vcpus'] == vcpus and row['scenario'] == scenario and row['phase'] == 'measure']
    a = [row['elapsed_ns'] for row in selected if row['arm'] == 'A']
    b = [row['elapsed_ns'] for row in selected if row['arm'] == 'B']
    need(a and b, f'No samples for {scenario}, {vcpus} vCPUs')
    ma, mb = statistics.median(a), statistics.median(b)
    return {'scenario': scenario, 'vcpus': vcpus, 'baseline_median_ns': ma,
            'optimized_median_ns': mb, 'reduction_percent': (ma - mb) * 100 / ma,
            'baseline_samples': len(a), 'optimized_samples': len(b)}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--baseline', required=True, type=Path)
    ap.add_argument('--optimized', required=True, type=Path)
    ap.add_argument('--out', required=True, type=Path)
    ap.add_argument('--build-record', type=Path)
    ap.add_argument('--integration', type=Path, default=Path('../源码与构建脚本/qemu/integration.json'))
    ap.add_argument('--vcpus', default=','.join(map(str, PROTOCOL['default_vcpus'])))
    ap.add_argument('--blocks', type=int, default=PROTOCOL['default_blocks'])
    ap.add_argument('--memory', default=PROTOCOL['memory'])
    ap.add_argument('--cpu', default=PROTOCOL['cpu'])
    ap.add_argument('--timeout', type=int, default=PROTOCOL['timeout_seconds'])
    ap.add_argument('--guest-kernel', type=Path)
    ap.add_argument('--guest-initrd', type=Path)
    ap.add_argument('--guest-append', default='console=ttyS0')
    ap.add_argument('--guest-vcpus', type=int, default=1)
    ap.add_argument('--guest-pass-marker', default='QEMU_GUEST_TEST_PASS')
    ap.add_argument('--guest-fail-marker', default='QEMU_GUEST_TEST_FAIL')
    ap.add_argument('--guest-elf', type=Path)
    ap.add_argument('--guest-elf-checksum')
    ap.add_argument('--guest-programs', type=Path,
                    help='manifest JSON with test program sources and compile commands (guest/build.sh output)')
    args = ap.parse_args()

    need(platform.system() == 'Linux' and platform.machine().lower() in ('riscv64', 'riscv64gc'),
         'Run this benchmark on the RISC-V Linux host that executes the tested QEMU binaries')
    baseline, optimized = args.baseline.resolve(), args.optimized.resolve()
    for binary in (baseline, optimized):
        need(binary.is_file(), f'QEMU executable not found: {binary}')
        elf_machine(binary)
    need(args.blocks > 0 and args.timeout > 0, 'blocks and timeout must be positive')
    vcpus = [int(value) for value in args.vcpus.split(',') if value]
    need(vcpus and all(value > 0 for value in vcpus), 'vcpus must be a comma-separated list of positive integers')
    linux_guest = args.guest_kernel is not None or args.guest_initrd is not None
    need((args.guest_kernel is None) == (args.guest_initrd is None), 'guest-kernel and guest-initrd must be supplied together')
    elf_guest = args.guest_elf is not None
    need(not (linux_guest and elf_guest), 'supply either guest-kernel/guest-initrd or guest-elf, not both')
    if linux_guest:
        args.guest_kernel = args.guest_kernel.resolve(); args.guest_initrd = args.guest_initrd.resolve()
        need(args.guest_kernel.is_file() and args.guest_initrd.is_file(), 'guest kernel/initrd file not found')
        need(args.guest_pass_marker and args.guest_fail_marker, 'guest gate markers cannot be empty')
    if elf_guest:
        args.guest_elf = args.guest_elf.resolve()
        need(args.guest_elf.is_file(), 'guest ELF file not found')
        need(args.guest_elf_checksum is not None, 'guest-elf-checksum is required with guest-elf')
        need(len(args.guest_elf_checksum) == 8 and all(c in '0123456789abcdefABCDEF' for c in args.guest_elf_checksum),
             'guest-elf-checksum must be 8 hexadecimal digits')
        args.guest_elf_checksum = args.guest_elf_checksum.lower()
    if linux_guest or elf_guest:
        need(args.guest_vcpus in vcpus, 'guest-vcpus must also appear in --vcpus')
    guest_programs = {}
    if args.guest_programs is not None:
        args.guest_programs = args.guest_programs.resolve()
        need(args.guest_programs.is_file(), 'guest-programs manifest not found')
        manifest = json.loads(args.guest_programs.read_text(encoding='utf-8'))
        for program in manifest.get('programs', []):
            need(program.get('name') and isinstance(program.get('command'), list)
                 and isinstance(program.get('sources'), dict), 'malformed guest-programs manifest')
            guest_programs[program['name']] = program
        need(guest_programs, 'guest-programs manifest lists no programs')
    integration_path = args.integration.resolve()
    integration = json.loads(integration_path.read_text(encoding='utf-8')) if integration_path.is_file() else {}
    build = json.loads(args.build_record.read_text(encoding='utf-8')) if args.build_record else {}
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    (out / 'raw').mkdir()
    arms = {'A': ('baseline', baseline), 'B': ('optimized', optimized)}
    versions = {label: subprocess.run([str(path), '--version'], check=True, capture_output=True, text=True).stdout.strip()
                for label, path in arms.values()}
    if guest_programs:
        test_program = {'path': str(args.guest_programs), 'sha256': sha256(args.guest_programs),
                        'programs': [program for program in manifest['programs'] if program['name'] in guest_programs]}
    else:
        test_program = {'path': str(Path(__file__).resolve()), 'sha256': sha256(__file__),
                        'compile_command': 'Not applicable; Python 3 standard-library runner'}
    environment = {'started_at': datetime.now(timezone.utc).isoformat(), 'host': dict(platform.uname()._asdict()),
                   'python': sys.version, 'affinity': sorted(os.sched_getaffinity(0)) if hasattr(os, 'sched_getaffinity') else None,
                   'binaries': {label: {'path': str(path), 'sha256': sha256(path), 'elf_machine': elf_machine(path),
                                        'version': versions[label]} for label, path in arms.values()},
                   'integration': integration, 'build_record': build,
                   'test_program': test_program,
                   'protocol': PROTOCOL, 'guest': None}
    if linux_guest:
        environment['guest'] = {'kind': 'linux', 'kernel': str(args.guest_kernel), 'kernel_sha256': sha256(args.guest_kernel),
                                'initrd': str(args.guest_initrd), 'initrd_sha256': sha256(args.guest_initrd),
                                'append': args.guest_append, 'vcpus': args.guest_vcpus,
                                'pass_marker': args.guest_pass_marker, 'fail_marker': args.guest_fail_marker}
    if elf_guest:
        environment['guest'] = {'kind': 'bare-metal', 'elf': str(args.guest_elf), 'elf_sha256': sha256(args.guest_elf),
                                'checksum': args.guest_elf_checksum, 'vcpus': args.guest_vcpus}
    save(out / 'environment.json', environment)

    def run_scenario(scenario, binary, n):
        if scenario == 'qmp-ready':
            return qmp_probe(binary, n, args.memory, args.cpu, args.timeout)
        if scenario == 'guest-ready':
            return guest_boot(binary, args.guest_vcpus, args.memory, args.cpu, args.guest_kernel,
                              args.guest_initrd, args.guest_append, args.guest_pass_marker,
                              args.guest_fail_marker, args.timeout)
        return guest_elf_boot(binary, args.guest_vcpus, args.memory, args.cpu, args.guest_elf,
                              args.guest_elf_checksum, args.timeout)

    rows, gates, commands = [], [], []
    try:
        for n in vcpus:
            probes = {}
            for arm, (label, binary) in arms.items():
                result = qmp_probe(binary, n, args.memory, args.cpu, args.timeout)
                probes[arm] = result
                gates.append({'gate': 'QMP startup and machine query', 'arm': arm, 'variant': label,
                              'vcpus': n, 'passed': True, 'qmp_device_type_count': result['device_type_count']})
                (out / 'raw' / f'gate-qmp-v{n}-{arm}.json').write_text(
                    json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
            need(probes['A']['machine_names'] == probes['B']['machine_names'], 'Baseline/optimized machine lists differ')
            need(probes['A']['device_types_sha256'] == probes['B']['device_types_sha256'], 'Baseline/optimized QOM device type sets differ')
        if linux_guest:
            for arm, (label, binary) in arms.items():
                result = run_scenario('guest-ready', binary, args.guest_vcpus)
                gates.append({'gate': 'Linux guest workload marker', 'arm': arm, 'variant': label,
                              'vcpus': args.guest_vcpus, 'passed': True, 'marker': result['marker']})
                (out / 'raw' / f'gate-guest-{arm}.json').write_text(
                    json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        if elf_guest:
            for arm, (label, binary) in arms.items():
                result = run_scenario('guest-elf-ready', binary, args.guest_vcpus)
                gates.append({'gate': 'Bare-metal guest RVWORK handshake and checksum', 'arm': arm,
                              'variant': label, 'vcpus': args.guest_vcpus, 'passed': True,
                              'checksum': result['checksum']})
                (out / 'raw' / f'gate-guest-elf-{arm}.json').write_text(
                    json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

        scenarios = ['qmp-ready'] + (['guest-ready'] if linux_guest else []) + (['guest-elf-ready'] if elf_guest else [])
        for n in vcpus:
            for scenario in scenarios:
                for arm in ('A', 'B'):
                    label, binary = arms[arm]
                    result = run_scenario(scenario, binary, n)
                    commands.append({'phase': 'warmup', 'scenario': scenario, 'arm': arm,
                                     'variant': label, 'vcpus': n, 'command': result['command']})
                for block in range(args.blocks):
                    for slot, arm in enumerate(order_for_block(block)):
                        label, binary = arms[arm]
                        result = run_scenario(scenario, binary, n)
                        row = {'phase': 'measure', 'scenario': scenario, 'vcpus': n, 'block': block,
                               'slot': slot, 'arm': arm, 'variant': label, 'elapsed_ns': result['elapsed_ns']}
                        rows.append(row)
                        commands.append({'phase': 'measure', **row, 'command': result['command']})
                        (out / 'raw' / f'{scenario}-v{n}-b{block}-s{slot}-{arm}.json').write_text(
                            json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        summaries = [median_summary(rows, n, scenario) for n in vcpus for scenario in scenarios]
        with (out / 'raw.csv').open('w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=['phase','scenario','vcpus','block','slot','arm','variant','elapsed_ns'])
            writer.writeheader(); writer.writerows(rows)
        save(out / 'commands.json', commands)
        save(out / 'correctness.json', {'status': 'PASS', 'gates': gates})
        save(out / 'summary.json', {'metric': 'elapsed time to QMP greeting / guest success marker / bare-metal RVWORK_DONE checksum; lower is better',
                                    'summaries': summaries, 'order_per_block': PROTOCOL['orders'],
                                    'warmup': 'one discarded launch per arm and scenario', 'blocks': args.blocks})
        save(out / 'run.json', {'status': 'PASS', 'environment': 'environment.json', 'correctness': 'correctness.json',
                                'raw_samples': 'raw.csv', 'summary': 'summary.json'})
        print(json.dumps({'status': 'PASS', 'out': str(out), 'summaries': summaries}, ensure_ascii=False, indent=2))
    except BaseException as exc:
        save(out / 'run.json', {'status': 'FAILED', 'error': repr(exc), 'gates_completed': gates,
                                'samples_completed': len(rows)})
        raise


if __name__ == '__main__':
    main()
