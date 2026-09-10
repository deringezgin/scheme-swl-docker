# Programming assignment runtime check — 2026-09-10

All 15 assignment folders were checked with native ARM64 SWL 1.3, Chez Scheme
10.4.1, and Aqua Tcl/Tk 8.6.18 on macOS 26.6.2. All 119 `.ss` source files passed
the Scheme reader. The course source files were unchanged; execution used copies,
private preferences, and random seed 42.

Of 23 submission/working-version cases, 19 completed their configured runs and
checks. The remaining four — minimax, both MCTS versions, and the final goal
version — passed bounded game checks. Their full runs were not completed within
the test limits. Five additional reference cases ran successfully; the supplied
Parker BFS and DFS reference files failed on an undefined variable.

This is a native-runtime check, not a grading review. A program returning normally
does not establish that every algorithm is correct, every grid is solvable, or
every learned model is accurate. Bounded checks do not establish full-game success.

| Assignment folder | What was exercised | Result |
|---|---|---|
| `ai_00_scheme_1` | Submitted file, its examples, and basic numeric checks | Completed |
| `ai_00_scheme_2` | Submitted file, its examples, list insertion and flattening checks | Completed |
| `ai_00_scheme_3` | Original `grid-main.ss` configuration | Completed; reached the goal in 81 steps |
| `ai_01_bfs_dfs` | Your BFS and DFS; path endpoints and adjacent steps checked | Completed; paths contained 9 and 13 nodes |
| `ai_02_bnb` | Original branch-and-bound main | Completed; reached the goal |
| `ai_03_rta_hc` | `grid-boss.ss`, including all five paired trials | Completed; four valid paired trials, averages RTA 58.5 / HC 40.0 |
| `ai_04a_minimax` | Original depth 8; bounded chase | Bounded check completed; full run reached 59 iterations before the 35-second limit |
| `ai_04b_mcts` | Goal and robot versions, original 5-second thinking budgets | Both bounded mains completed; full ten-game bosses exceeded 45 seconds |
| `ai_05_propositional_logic` | All 20 built-in generated test cases | Completed |
| `ai_06_first_order_logic` | `propSearch.ss`, `propSearchNEW.ss`, and `propSearchOLD.ss` | All completed; current version found the goal, NEW/OLD reported `not found` |
| `ai_07_production_systems` | Favoring and Best rule variants | Both completed and reached the goal |
| `ai_08_neural_network` | NN0 and NN1, all four inputs with their active AND weights | Completed; both default truth tables passed |
| `ai_09_perceptron` | Entire logic and passability training scripts | Completed: 36 logic and 12 passability configurations, including the million-update settings |
| `ai_10_genetic_algorithms` | Full 10,000-generation default run; population and three fitness-function checks | Completed; maximum population fitness increased from 1684 to 1874 |
| `ai_11_final_assignment` | Goal and robot submission versions | Goal: bounded check completed, full run exceeded 45 seconds. Robot: full run reached the goal in 29 steps |

## Limits and issues found

- `ai_01_bfs_dfs/parker_bfs_dfs/grid-BFS.ss` and `grid-DFS.ss` reference versions
  use `visited` without defining it. Both fail in native SWL. A minimal call to
  their `search` functions also reproduces `variable visited is not bound` in
  the original Petite 8.4 container. Your submitted BFS and DFS already contain
  `(define visited 1)` and pass.
- The genetic-algorithm display helper `get-best-individual` sorts fitness in
  ascending order and takes the first individual, so the printed "best" is
  actually the lowest-fitness individual. The report above computes the maximum
  independently. Also, the default chromosome has 8 genes while `int-target-lst`
  has 10 elements; part 3 can only compare the first 8 target values under those
  settings. Neither issue prevents the default program from running.
- Perceptron runs completed, but some configurations misclassified inputs. This
  is learning behavior, not a runtime exception; the assignment explicitly asks
  about XOR and large learning rates. These runs do not establish model quality.
- The short game checks set the chase limit to 4 iterations and remove animation
  busy-waits in copied files. Search depths, rollout counts, and MCTS thinking
  budgets stay unchanged. For MCTS, the main file runs with `scores` initialized;
  its ten-game boss and capture average are not part of the short check.
- The initial minimax test exited without its completion marker while the
  isolated driver did not keep an SWL application registered during a long load.
  The corrected driver continued through 59 iterations before its time limit.
  The first bounded MCTS attempt also tried to average zero completed captures;
  the final bounded checks run the main program directly. These intermediate
  results are retained in the raw logs and are not treated as submission failures.
- Full graphical comparison runs for the two failing reference files exceeded
  the container's 30-second limit. The Petite comparison above is a minimal
  non-graphical reproduction of the missing variable, not a completed container
  GUI test.

## Repeat the checks

From the repository root, with a logged-in Mac desktop:

```sh
python3 native-macos/check-assignments.py --timeout 45
```

Run the short checks for the long game programs:

```sh
python3 native-macos/check-assignments.py --bounded --timeout 50 \
  --case ai4a-minimax --case ai4b-mcts-goal --case ai4b-mcts-robot \
  --case ai11-final-goal --case ai11-final-robot
```

The runner prints each case's outcome and the report directory. It saves copied
sources, source hashes, drivers, complete program output, runtime logs, and
machine-readable results under `.native-macos/assignment-audit/`. `PASS` means
the entry point and explicit checks completed; `TIMEOUT` means execution was
stopped at the stated limit; `INCOMPLETE` means the process exited without the
completion marker. Actual Scheme exceptions appear in `error.txt`.

## Local evidence

These artifacts are local build outputs and are not included in a fresh clone:

- [Initial 30-case run](../.native-macos/assignment-audit/20260910T210523.504247Z/report.md)
- [Bounded minimax and final-project checks](../.native-macos/assignment-audit/20260910T210934.806167Z/report.md)
- [Corrected bounded MCTS checks](../.native-macos/assignment-audit/20260910T211137.702818Z/report.md)
- [Minimax run with its session kept alive](../.native-macos/assignment-audit/20260910T211257.018658Z/report.md)
- [Petite reference-error reproduction](../.native-macos/assignment-audit/reference-petite-comparison.txt)
- [Reader check for all 119 Scheme files](../.native-macos/assignment-audit/source-read-check.txt)
