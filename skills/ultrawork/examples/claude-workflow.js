// Claude ultracode Workflow DSL example. This is not standalone Node.js.
// Invoke with args: { cap, target, out, lenses }. Keep lenses distinct and len >= cap.

export const meta = {
  name: 'audit-target',
  description: 'Multi-lens find, draft, batched refute, and final report',
  phases: [{ title: 'find' }, { title: 'draft' }, { title: 'verify' }, { title: 'final' }],
}

const CAP = Number(args.cap)
const TARGET = args.target
const OUT = args.out
const LENSES = args.lenses

if (!Number.isInteger(CAP) || CAP < 1) throw new Error('args.cap must be a positive integer')
if (typeof TARGET !== 'string' || !TARGET) throw new Error('args.target is required')
if (typeof OUT !== 'string' || !OUT) throw new Error('args.out is required')
if (!Array.isArray(LENSES) || LENSES.length < CAP || new Set(LENSES).size !== LENSES.length) {
  throw new Error('args.lenses must contain at least args.cap distinct lenses')
}

const FINDINGS = {
  type: 'object', required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', required: ['title', 'severity', 'file', 'evidence', 'suggested_fix'],
    properties: {
      title: { type: 'string' }, severity: { enum: ['critical', 'high', 'medium', 'low'] },
      file: { type: 'string' }, evidence: { type: 'string' }, suggested_fix: { type: 'string' },
    },
  } } },
}

const VERDICTS = {
  type: 'object', required: ['verdicts'],
  properties: { verdicts: { type: 'array', items: {
    type: 'object', required: ['id', 'refuted', 'why'],
    properties: { id: { type: 'string' }, refuted: { type: 'boolean' }, why: { type: 'string' } },
  } } },
}

const writeReport = (found, verdicts, ph) => agent(
  `Overwrite ${OUT} with a synthesized audit report.

- Rank and deduplicate findings without dropping any status.
- Include title, severity, file:line, evidence, and suggested fix.
- Missing verdict: unverified. refuted=true: refuted. Otherwise: confirmed.
- Put confirmed, refuted, and unverified counts first.

FINDINGS: ${JSON.stringify(found)}
VERDICTS: ${JSON.stringify(verdicts)}`,
  { label: `report:${ph}`, phase: ph },
)

// Each wave is bounded by CAP; the draft waits for the complete discovery set.
phase('find')
const found = []
for (let start = 0; start < LENSES.length; start += CAP) {
  const batch = LENSES.slice(start, start + CAP)
  const results = (await parallel(batch.map((lens) => () =>
    agent(`Audit ${TARGET} only through this lens: ${lens}.
Return every concrete defect with file:line evidence.`,
    { label: `find:${lens}`, phase: 'find', schema: FINDINGS }),
  ))).filter(Boolean)

  results.forEach((result, i) => {
    result.findings.forEach((finding, j) => {
      found.push({ ...finding, id: `${start + i}-${j}`, lens: batch[i] })
    })
  })
}

phase('draft')
await writeReport(found, [], 'draft')
log(`${found.length} findings drafted to ${OUT}; verification starts now`)

// Group same-file claims so one verifier reads each source once.
phase('verify')
const groups = Array.from({ length: CAP }, () => [])
;[...new Set(found.map((finding) => finding.file))].forEach((file, i) => {
  groups[i % CAP].push(...found.filter((finding) => finding.file === file))
})

let verdicts = (await parallel(groups.filter((group) => group.length).map((group, i) => () =>
  agent(`Try to REFUTE every finding below. Return exactly one verdict per id.

${JSON.stringify(group)}`,
  { label: `verify:batch-${i}`, phase: 'verify', schema: VERDICTS }),
))).filter(Boolean).flatMap((result) => result.verdicts)

// Escalate every disagreement in at most CAP batches; never one agent per claim.
const contested = verdicts.filter((verdict) => verdict.refuted)
if (contested.length && (!budget.total || budget.remaining() > 50_000)) {
  const rehearingGroups = Array.from({ length: Math.min(CAP, contested.length) }, () => [])
  contested.forEach((verdict, i) => {
    rehearingGroups[i % rehearingGroups.length].push({
      finding: found.find((item) => item.id === verdict.id),
      refutation: verdict,
    })
  })
  const second = (await parallel(rehearingGroups.map((group, i) => () =>
    agent(`Independently decide whether each refutation holds. Return one verdict per finding id.

${JSON.stringify(group)}`,
    { label: `rehear:batch-${i}`, phase: 'verify', schema: VERDICTS }),
  ))).filter(Boolean).flatMap((result) => result.verdicts)
  const reheard = new Set(second.map((verdict) => verdict.id))
  verdicts = [...verdicts.filter((verdict) => !reheard.has(verdict.id)), ...second]
}

phase('final')
await writeReport(found, verdicts, 'final')
return {
  out: OUT,
  total: found.length,
  refuted: verdicts.filter((verdict) => verdict.refuted).length,
  unverified: found.filter((finding) => !verdicts.some((verdict) => verdict.id === finding.id)).length,
}
