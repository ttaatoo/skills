# go-naming Benchmark History

> **Provenance:** reconstructed on 2026-08-01 from the run summaries of
> `skills/go-naming-workspace/`, which was removed before it could be archived. The
> per-eval `grading.json` / `timing.json` artifacts are gone; the numbers and the one
> recorded failure below are what survived. Future runs should write here directly.

## Iteration 3 — 2026-08-03T09:17:21Z

Evals 1–7 (eval 7 added this iteration: fresh-module naming — module path, package/local-var
collision, single-letter constants). **Single-pass** (1 run per configuration; timing/tokens
not captured this run). Grading scripted + one judgment check; grader false-positives
(`w = f` matched as a const; noun comma-ok missed) were found and corrected before scoring.

| Metric | With Skill | Without Skill | Delta |
|---|---|---|---|
| Pass Rate | 100% (38/38) | 95% (36/38) | +0.05 |
| Time | n/a | n/a | n/a |
| Tokens | n/a | n/a | n/a |

Per-eval deltas: eval-2 +0.20 (without wrote `Getenv` — borderline stdlib mirror), eval-7
+0.20 (without used bare-word module path `csvmerge` vs with `example.com/csvdedup`);
evals 1, 3, 4, 5, 6 → 0 delta.

## What iteration 3 tells us

- **No regression from the four additive edits** (intention-revealing framing, package/local-var
  collision, single-letter constants, module-path ownership): evals 1–6 all still pass 100%.
- **The module-path rule is the one clearly-skill-driven new behavior.** The without-skill run
  reached for a bare-word module path; the with-skill run produced a host/path form. The other
  new rules showed no delta — the model already gets single-letter constants and package naming
  right unaided, consistent with the form-layer-noise lesson from iterations 1–2.
- **eval-3 (mapper firewall) is non-discriminating** — both configs built a correct firewall.
  Go initialism casing is baseline knowledge for this model. Keep the eval as a regression
  guard, but don't expect it to show skill value.
- **Reinforces the standing lesson:** aim future evals at *semantic* naming and *other-language
  drift resistance* (grab-bag packages, `Getenv`, bare module paths), not form the model
  already knows.

## Iteration 2 — 2026-07-31T15:20:24Z

Evals 1–6, 3 runs per configuration.

| Metric | With Skill | Without Skill | Delta |
|---|---|---|---|
| Pass Rate | 93% ± 16% | 73% ± 24% | +0.20 |
| Time | 263.7s ± 92.4s | 164.6s ± 67.5s | +99.1s |
| Tokens | 19071 ± 68 | 21394 ± 2019 | −2323 |

## Iteration 1 — 2026-07-31T10:39:03Z

Evals 1–3, 3 runs per configuration.

| Metric | With Skill | Without Skill | Delta |
|---|---|---|---|
| Pass Rate | 93% ± 12% | 87% ± 23% | +0.07 |
| Time | 286.7s ± 67.2s | 165.8s ± 49.6s | +120.9s |
| Tokens | 19262 ± 182 | 22593 ± 1232 | −3331 |

## What the two iterations tell us

- **The form layer is not where the skill earns its keep.** Iteration 1's evals (package
  layout, grab-bag packages, acronym casing) gave +0.07 with a standard deviation several
  times the effect — the model mostly gets form right unaided. Iteration 2 added
  semantic-layer evals (`eval-absence-contract`, `eval-verb-consistency`,
  `eval-restart-action-naming`) and the delta jumped to +0.20. Keep future evals aimed at
  semantics; form-layer evals mostly measure noise.
- **Cost is ~100s of wall clock, but ~2.3k *fewer* output tokens.** Having a convention to
  follow is cheaper than improvising one. The time goes into the `look` step (listing
  directories, grepping neighbors), which is also the step that produces the win.
- **Recorded failure, iteration 2, `eval-verb-consistency`:** given a type with
  `AcquireLease`/`ReleaseLease`, the model added `DiscardLease` instead of reusing
  `Release*`. Fixed by making "grep the type's existing **verb set**, not just its receiver
  name" an explicit second grep in `SKILL.md` §1 and a self-check item. Re-run this eval
  first when next benchmarking.

## Iteration 4 — 2026-08-05 (restructure; regression check only)

Structural/cost changes only; no new naming rules. Every rule present before is still present.

**This is not a delta measurement.** One run, `with_skill` only, 2 of the 7 evals. It answers
one question — did the restructure break anything — and nothing else. Pass rate against
iteration 3's with-skill baseline:

| Eval | Router row the agent took | Result | iter-3 |
|---|---|---|---|
| eval-1 new service package | widest (§2 full + §4 + §7) | 7/7 | 7/7 |
| eval-6 verb consistency | widest — see below | 5/5 | 5/5 |

**No regression on naming quality.** eval-6 is the one historically-recorded failure (iteration 2:
the model added `DiscardLease` beside `AcquireLease`/`ReleaseLease`) and it now passes: the model
produced `ReleaseBrokenLease`, reused `Fetch` for `FetchReportVersions` rather than drifting to
`Get`/`Retrieve`, and documented the reuse at the declaration ("The Release verb is reused
deliberately so the lease teardown vocabulary stays consistent").

**But the router's narrow rows were never exercised, and this harness cannot exercise them.**
eval-6 was expected to take the narrow "adding one method to an existing type" row — the row that
skips the §4 table, and the only plausible regression path. It didn't. The agent reported the task
as spanning two rows ("creating a file" + "adding methods to an existing type") and applied
*"If a change spans rows, run the widest one"*, so it ran §2 + §4 + §7 in full. That is the router
behaving as written, not a bug.

The cause is structural: **every eval writes into a fresh empty `outputs/` directory, so the agent
is always creating a file, so the widest row always wins.** Rows 1, 2, 4 and 5 of the router are
unreachable by this harness as designed. An eval that tests a narrow row must seed a populated
package on disk and ask for one added method inside an existing file — otherwise the router is
being scored on the one path that changes nothing.

Both agents also loaded `references/semantic-naming.md` in full, and eval-1 loaded
`references/rules-bank.md` in full as well. Correct for the widest row, but it means this round
shows no reference-tier token saving either — the widest row loads nearly everything.

Manual re-grading found no false positives this round (iteration 3 had two). One borderline call
worth recording: eval-1 named its interface `exportprogress.Service`, and §3's filler test lists
`Service` as a zero-information word. Scored as a pass — the filler test is about deleting a word
from a multi-word name (`sheets.SheetsService`), and there is no word to delete here. If a future
iteration wants that to fail, the rule needs to say so explicitly rather than relying on the
grader's judgment.

**What this round does not show:** no `without_skill` arm, so no delta; evals 2, 3, 4, 5, 7
were not re-run; no timing or token capture; and no narrow router row was reached, so neither the
router's saving nor its regression risk was measured at all.

**Cross-skill routing probe — 2 independent runs, both passed.** Fresh agents were given a Go
design question with two trade-offs the rule book doesn't settle (export a sentinel error for
"not found" or keep it opaque; whether to launch an internal prefetch goroutine) and asked to
report their routing. Both runs invoked `dave-cheney-go` **only**, both quoted the same triggering
clause (*"whether to launch a goroutine at all, whether to export a sentinel error or a concrete
error type"*), both rejected `effective-go` as "not a concrete idiom question" and `go-naming` by
quoting this skill's boundary note back verbatim (*whether* to expose vs *how to name*), and both
reported no conflicts and no gaps. The rejected *fourth* skill differed between runs
(`go-backend-tech-design` / `codebase-design`), so routing inside the Go triangle replicates while
the outer rejection depends on what else is in view.

Both runs also quoted reference-tier content accurately (the error-exposure escalation ladder,
"Exported error identity is API forever", "Leave concurrency to the caller", the red flag
*stop condition is "the process exits"*), confirming `references/design-decisions.md` is being
loaded and used rather than answered from SKILL.md alone.

**One divergence worth a future test:** the two runs implemented row 2 of the escalation ladder
differently — one used an unexported behavior interface with `errors.As`, the other an unexported
sentinel with `errors.Is`. Both are defensible and both stay inside the ladder, but
`design-decisions.md` documents only the behavior-interface form. If that row should be
deterministic, the reference must say which form applies when (a behavior interface earns its keep
across package boundaries; a lone predicate does not need one). Not changed here — no failing test
for it yet.

This is the first evidence of any kind for `dave-cheney-go`, which still has **no evals of its
own**, and it tests routing, not answer quality.

### What changed

- **§1 Scope router added.** Five rows keyed to what's being named, bounding how much process
  runs. Motivated by iterations 1–3 measuring **+100s wall clock** for the `look` step: that
  cost is worth paying for a new package and not for a loop variable.
- **§7 self-check compressed to pointer form**; expanded version with rationale and greps moved
  to `references/self-check.md`.
- **§4 table rows trimmed** — reasoning prose moved to `references/rules-bank.md` (which already
  carried it). Added a `Module path` row, previously only implied by eval-7.
- **Two defects fixed:** §4's intro sentence was ungrammatical (`Src` had no subject), and §3
  was titled "The three tests" while listing four.
- **`description` rewritten** to "Use when …" form, rationale tail dropped, Chinese triggers kept.
- **Cross-references added** to `effective-go` and `dave-cheney-go`, including an explicit note
  that `dave-cheney-go`'s "prefer opaque errors" and this skill's `ErrXxx` rule operate at
  different layers (whether to expose vs how to name).
- SKILL.md: **2506 → 2336 words.** Smaller than intended: ~440 words of old content left
  (self-check body, table prose, intro), but ~270 words of new content came in (the router and
  the neighbouring-skills routing). All 20 original table rules are still present, plus the new
  `Module path` row. The always-loaded tier did not get dramatically cheaper — the honest win is
  that ~440 words became load-on-demand and the process is now scoped.

**Where the remaining fat is, and the untested hypothesis:** §4's table is 578 words of the 2336
and is mostly data, not prose — it can't be compressed further without evicting rules. Iterations
1–3 showed the form layer is near-baseline for this model (eval-3 explicitly non-discriminating),
which suggests the low-delta form rows (acronyms, type params, doc comments, canonical names,
variable/constant type-encoding) could move to `rules-bank.md` for a further ~200-word cut, since
§5's linters catch all of them anyway. **This was deliberately not done blind** — evals 2, 3 and 7
grade acronym casing and constant naming directly. Test it as a separate arm rather than bundling
it with the restructure.

**Still owed, and the reason the router's value is unproven:** the router was justified by the
+100s wall clock that iterations 1–2 measured for the `look` step, but no eval measures that cost.
Nothing here proves a trivial one-helper change now *skips* the directory listing — only that the
naming stays correct when it does. That eval needs to assert on process (no `ls`, one grep, not
three) with timing captured, and it is not written. Until then the router is a verified
non-regression and an asserted saving.

**Next benchmark should:** re-run all 7 evals with both arms (this round dropped `without_skill`
entirely), capture timing/tokens again, and add the cost eval above — seeding an existing populated
package so a narrow row is actually reachable. Test the §4 row-eviction hypothesis as its own arm,
not bundled. `dave-cheney-go` needs its own evals; a routing probe is not one.

## Re-running

The eval definitions live in [evals.json](evals.json) (7 evals, Chinese prompts, all
writing to `outputs/`, graded on grep-able evidence). Use the `skill-creator` skill's
benchmark flow, and copy the resulting `benchmark.md` summary into this file rather than
leaving it in a scratch workspace.
