#!/usr/bin/env python3
"""Run the local COM316 programs in isolated native SWL sessions and save evidence.

This is a runtime compatibility check, not assignment grading. Source files are
copied before execution; optional algorithm selections affect only those copies.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

REPO = Path(__file__).resolve().parent.parent


def cases():
    result = []

    def add(name, entry, post='', replacements=None, reference=False):
        result.append(dict(name=name, entry=entry, post=post,
                           replacements=replacements or [], reference=reference))

    add('scheme1', 'ai_00_scheme_1/derin_gezgin_scheme1.ss', '''
(assert (not (is_big 1000)))
(assert (is_big 1001))
(assert (= (dist 0 0 3 4) 5))
(assert (= (count_twos '(2 1 2 3)) 2))
''')
    add('scheme2', 'ai_00_scheme_2/derin_gezgin_scheme2.ss', '''
(assert (equal? (sqr-list '(1 2 3)) '(1 4 9)))
(assert (equal? (place 2 '(1 3)) '(1 2 3)))
(assert (equal? (flatten '(1 (2 (3)) 4)) '(1 2 3 4)))
''')
    state = '(printf "FINAL start=~s robot=~s goal=~s reached=~s\\n" start robot goal (equal? robot goal))'
    path = '''
(define audit-path (get-path goal))
(assert (equal? (car audit-path) goal))
(assert (equal? (car (reverse audit-path)) start))
(let loop ([p audit-path])
  (unless (null? (cdr p))
    (assert (= (+ (abs (- (caar p) (caadr p)))
                  (abs (- (cadar p) (cadadr p)))) 1))
    (loop (cdr p))))
(printf "VALID_PATH nodes=~a\\n" (length audit-path))
'''
    add('scheme3', 'ai_00_scheme_3/grid-main.ss', state)
    for alg in ['DFS', 'BFS']:
        add('ai1-' + alg.lower(), 'ai_01_bfs_dfs/grid-main.ss', path,
            [('grid-main.ss', '(load "grid-DFS.ss")', f'(load "grid-{alg}.ss")')])
    add('ai2-bnb', 'ai_02_bnb/grid-main.ss', state)
    add('ai3-rta-hc', 'ai_03_rta_hc/grid-boss.ss',
        '(printf "TOTALS rta=~s hc=~s\\n" total-rta total-hc)')
    add('ai4a-minimax', 'ai_04a_minimax/grid-main.ss', state)
    for side in ['goal', 'robot']:
        add('ai4b-mcts-' + side, f'ai_04b_mcts/10_17_ai_4b_{side}/grid-boss.ss',
            '(printf "SCORES ~s\\n" scores)')
    add('ai5-propositional', 'ai_05_propositional_logic/propSearch.ss',
        '(assert (= (length rules) 33))')
    for suffix in ['', 'NEW', 'OLD']:
        add('ai6-fol' + ('-' + suffix.lower() if suffix else ''),
            f'ai_06_first_order_logic/propSearch{suffix}.ss',
            '(printf "FINAL_FACTS ~s\\n" facts)')
    for version in ['Favoring', 'Best']:
        add('ai7-production-' + version.lower(), 'ai_07_production_systems/grid-main.ss', state,
            [('grid-main.ss', '(load "grid-ProductionSystem-Favoring.ss")',
              f'(load "grid-ProductionSystem-{version}.ss")')])
    for file in ['NN0.ss', 'NN1.ss']:
        add('ai8-' + Path(file).stem.lower(), 'ai_08_neural_network/' + file, '''
(define audit-nn (map (lambda (x) (car (NN x))) '((0 0) (0 1) (1 0) (1 1))))
(assert (equal? (map (lambda (x) (if (> x 0.5) 1 0)) audit-nn) '(0 0 0 1)))
(printf "AND_TRUTH_TABLE ~s\\n" audit-nn)
''')
    for training in ['logic', 'passability']:
        add('ai9-' + training, f'ai_09_perceptron/train-test-{training}.ss',
            '(assert (for-all (lambda (x) (and (real? x) (finite? x))) threshold-weights))')
    add('ai10-ga', 'ai_10_genetic_algorithms/GAcode.ss', '''
(assert (= (length final-population) inds-per-pop))
(assert (for-all (lambda (x) (= (length x) (length gene-list-bits))) final-population))
(assert (= (part-1 '(1 2 3)) 6))
(assert (= (part-2 '(10 11 20)) 2))
(assert (= (part-3 int-target-lst) (length int-target-lst)))
(printf "FITNESS initial-max=~s final-max=~s\\n"
  (apply max (GAevaluate-pop starting-population))
  (apply max (GAevaluate-pop final-population)))
''')
    for side in ['goal', 'robot']:
        add('ai11-final-' + side, f'ai_11_final_assignment/ai_11_{side}/grid-main.ss', state)

    # These supplied reference/archival versions are separate from submissions.
    for alg in ['BFS', 'DFS']:
        add('reference-ai1-' + alg.lower(), 'ai_01_bfs_dfs/grid-main.ss', state,
            [('grid-main.ss', '(load "grid-DFS.ss")', f'(load "parker_bfs_dfs/grid-{alg}.ss")')], True)
    add('reference-ai4b', 'ai_04b_mcts/ai_4b_original_files/grid-main.ss', state, reference=True)
    add('reference-ai8', 'ai_08_neural_network/NN0_original.ss',
        '(for-each (lambda (x) (printf "NN ~s => ~s\\n" x (NN x))) \'((0 0) (0 1) (1 0) (1 1)))', reference=True)
    add('reference-ai9', 'ai_09_perceptron/perceptron_original.ss', '''
(load "perceptron-input.txt")
(do-learning training-input 1000)
(printf "WEIGHTS ~s\\n" threshold-weights)
''', reference=True)
    add('reference-ai10', 'ai_10_genetic_algorithms/GAcode_original.ss', '''
(define audit-pop (GAtrain (make-pop) 1000))
(assert (= (length audit-pop) inds-per-pop))
''', reference=True)
    add('reference-ai11', 'ai_11_final_assignment/ai_11_original_files/grid-main.ss', state, reference=True)
    return result


DRIVER = '''(import swl:module-setup)
(import swl:threads)
;; Keep the isolated session alive while loading a long command-line program.
;; An interactive REPL normally supplies this registration; our driver exits
;; before creating that REPL, so relying on the temporary splash is insufficient.
(swl:begin-application
  (lambda (token) (lambda () (swl:end-application token))))
(thread-sleep 1)
(define audit-output
  (open-file-output-port (getenv "SWL_AUDIT_OUTPUT")
    (file-options no-fail) (buffer-mode line) (native-transcoder)))
(guard (condition
  [else
    (with-output-to-file (getenv "SWL_AUDIT_ERROR")
      (lambda () (display-condition condition)) 'replace)
    (flush-output-port audit-output)
    ((foreign-procedure "_exit" (int) void) 1)])
  (current-directory (getenv "SWL_AUDIT_CWD"))
  (random-seed 42)
  (parameterize ([current-output-port audit-output] [current-error-port audit-output])
    (load (getenv "SWL_AUDIT_PRE"))
    (load (getenv "SWL_AUDIT_ENTRY"))
    (load (getenv "SWL_AUDIT_POST")))
  (thread-sleep 200)
  (flush-output-port audit-output)
  (with-output-to-file (getenv "SWL_AUDIT_SUCCESS")
    (lambda () (display "PROGRAM_AND_CHECKS_COMPLETED\\n")) 'replace)
  ((foreign-procedure "_exit" (int) void) 0))
'''


def hashes(source):
    return {str(p.relative_to(source)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(source.rglob('*')) if p.is_file()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assignments', type=Path,
                        default=REPO / 'COM316-ArtificialIntelligence/programming_assignments')
    parser.add_argument('--case', action='append', help='Run only this case (repeatable).')
    parser.add_argument('--timeout', type=int, default=60, help='Seconds per isolated case.')
    parser.add_argument('--bounded', action='store_true',
                        help='Test copies only: remove animation delays, limit chase to 4 steps and bosses to 1 trial.')
    parser.add_argument('--backend', choices=['native', 'container'], default='native',
                        help='Use the existing course container only for comparison of failures.')
    args = parser.parse_args()
    source = args.assignments.resolve()
    runtime = Path(os.environ.get('SWL_MACOS_ROOT', str(REPO / '.native-macos'))).resolve()
    launcher = runtime / 'runtime/bin/swl'
    if not launcher.exists() or not source.is_dir():
        parser.error('Build native SWL and provide an existing assignment directory first.')
    selected = [c for c in cases() if not args.case or c['name'] in args.case]
    if not selected or (args.case and set(args.case) - {c['name'] for c in selected}):
        parser.error('Unknown case. Available: ' + ', '.join(c['name'] for c in cases()))
    run = runtime / 'assignment-audit' / datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
    run.mkdir(parents=True)
    before = hashes(source)
    (run / 'source-sha256.json').write_text(json.dumps(before, indent=2) + '\n')
    print('Reports: ' + str(run), flush=True)
    results = []
    for case in selected:
        directory = run / case['name']
        directory.mkdir()
        entry = Path(case['entry'])
        work = directory / 'source'
        shutil.copytree(source / entry.parent, work)
        for filename, old, new in case['replacements']:
            target = work / filename
            text = target.read_text()
            if text.count(old) != 1:
                raise RuntimeError(f'{target}: expected exactly one occurrence of {old}')
            target.write_text(text.replace(old, new))
        adjustments = []
        executed_entry = entry.name
        prelude = ''
        if args.bounded:
            if case['name'].startswith('ai4b-mcts-'):
                # The boss averages completed captures. A deliberately capped
                # game can have zero captures, so its average is not meaningful.
                executed_entry = 'grid-main.ss'
                prelude = "(define scores '())\n"
            for target in sorted(work.glob('*.ss')):
                text = target.read_text()
                changed = re.sub(r'\(define pause-num \d+\)', '(define pause-num 0)', text)
                changed = re.sub(r'\(search grid (?:10000|20000)\)', '(search grid 4)', changed)
                changed = re.sub(r'\(run-tests 10\)', '(run-tests 1)', changed)
                changed = re.sub(r'\(define test-count 5\)', '(define test-count 1)', changed)
                if changed != text:
                    target.write_text(changed)
                    adjustments.append(target.name)
        driver = directory / 'driver.ss'
        driver.write_text(DRIVER)
        post = directory / 'post.ss'
        post.write_text(case['post'])
        pre = directory / 'pre.ss'
        pre.write_text(prelude)
        (directory / 'preferences').mkdir()
        env = dict(os.environ, SWL_NO_SERVER='1', SWL_PREFS_DIR=str(directory / 'preferences'),
                   SWL_AUDIT_OUTPUT=str(directory / 'program-output.txt'),
                   SWL_AUDIT_ERROR=str(directory / 'error.txt'), SWL_AUDIT_CWD=str(work),
                   SWL_AUDIT_ENTRY=str(work / executed_entry), SWL_AUDIT_POST=str(post),
                   SWL_AUDIT_PRE=str(pre),
                   SWL_AUDIT_SUCCESS=str(directory / 'success.txt'))
        command = [str(launcher), str(driver)]
        if args.backend == 'container':
            def container_path(path):
                return '/workspace/' + str(Path(path).relative_to(REPO))
            command = ['docker', 'compose', 'exec', '-T', '-e', 'USER=swl-audit-' + case['name']]
            for key, value in env.items():
                if key.startswith('SWL_AUDIT_') or key == 'SWL_PREFS_DIR':
                    command += ['-e', key + '=' + container_path(value)]
            command += ['scheme', 'timeout', '--kill-after=2s', str(args.timeout) + 's',
                        'sh', '/usr/bin/swl', container_path(driver)]
        print('RUN ' + case['name'], flush=True)
        start = time.monotonic()
        with (directory / 'runtime.log').open('w') as log:
            try:
                process = subprocess.run(command, env=env, cwd=REPO,
                                         stdout=log, stderr=subprocess.STDOUT,
                                         timeout=args.timeout + (5 if args.backend == 'container' else 0))
                if args.backend == 'container' and process.returncode in [124, 137]:
                    status = 'TIMEOUT'
                elif process.returncode == 0:
                    status = 'PASS' if (directory / 'success.txt').exists() else 'INCOMPLETE'
                else:
                    status = 'FAIL'
                code = process.returncode
            except subprocess.TimeoutExpired:
                status, code = 'TIMEOUT', None
        error = (directory / 'error.txt').read_text() if (directory / 'error.txt').exists() else ''
        result = dict(case, status=status, exit_code=code,
                      backend=args.backend, executed_entry=executed_entry,
                      bounded=args.bounded, adjusted_files=adjustments,
                      seconds=round(time.monotonic() - start, 2), error=error,
                      evidence=str(directory.relative_to(run)))
        results.append(result)
        (run / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
        print(f'{status} {case["name"]} ({result["seconds"]}s) {error}', flush=True)
    unchanged = before == hashes(source)
    report = ['# SWL assignment checks', '', 'Backend: ' + args.backend, '',
              'Host: ' + subprocess.check_output(['sw_vers', '-productVersion'], text=True).strip(),
              '', f'Seed: 42. Timeout: {args.timeout}s per program. Original files unchanged: {unchanged}.', '',
              'Bounded test copies: ' + str(args.bounded) +
              ' (when enabled: no animation delay, at most 4 chase iterations; MCTS thinking budgets unchanged; '
              'MCTS main is run directly with scores initialized, without the boss average of captures).', '',
              'PASS means the entry point returned without an exception and its listed runtime checks passed. '
              'It does not mean the assignment is fully correct or that every search reached a goal. '
              'TIMEOUT means the run was stopped at the stated wall-clock limit.', '',
              '| Case | Entry point | Result | Seconds | Error |',
              '|---|---|---|---:|---|']
    for r in results:
        error = r['error'].replace('\n', ' ').replace('|', '\\|')
        report.append(f'| {r["name"]} | `{r["entry"]}` | {r["status"]} | {r["seconds"]} | {error} |')
    report.extend(['', 'Each case directory contains a copy of its sources, the check driver, '
                   'program output, runtime log, and a success marker or error when available. '
                   'Algorithm selections are recorded in results.json; reference cases are labeled separately.', ''])
    (run / 'report.md').write_text('\n'.join(report))
    (runtime / 'assignment-audit/latest.txt').write_text(str(run) + '\n')
    print('Report: ' + str(run / 'report.md'), flush=True)
    if not unchanged:
        raise SystemExit('Assignment sources changed during the run; inspect source-sha256.json.')


if __name__ == '__main__':
    main()
