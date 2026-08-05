# Generated Code Is a Firewall

protobuf (and similar) code generators emit Go that violates Go naming conventions:
`SessionId`, `ApiBaseUrl`, `GetHeroId()`, `OutputJson`. You cannot fix generated files —
they get regenerated. Your job is to keep their conventions quarantined so they don't
colonize hand-written code. This is the single biggest source of `Id`/`Url`/`Json` casing
drift in real Go codebases.

## The rules

1. **Hand-written types always use correct Go casing.** Domain structs, params, results,
   interface methods: `SessionID`, `APIBaseURL`, `HeroID`, `CardJSON`. No exceptions,
   even when the proto field beside them is `session_id` / `SessionId`.

2. **Conversion happens once, in a mapper.** A dedicated converter file is the only place
   you own where both casings appear — necessarily on adjacent lines:

   ```go
   // converter.go — the firewall. proto casing on the left, Go casing on the right.
   func toProto(turn *domain.Turn) *pb.Turn {
       return &pb.Turn{
           SessionId:    turn.SessionID,
           ApiBaseUrl:   turn.APIBaseURL,
           CardJson:     turn.CardJSON,
       }
   }

   func fromProto(p *pb.Turn) *domain.Turn {
       return &domain.Turn{
           SessionID:  p.GetSessionId(),
           APIBaseURL: p.GetApiBaseUrl(),
           CardJSON:   p.GetCardJson(),
       }
   }
   ```

   Everything upstream of the mapper sees only `domain.Turn` with correct casing.

3. **Don't propagate generated getters.** Generated `GetX()` accessors are nil-safe
   accessors for proto's world. Your own interfaces don't inherit the style:

   ```go
   // ❌ the proto's getter shape leaked into a hand-written interface
   type RangeInfo interface {
       GetSheetName() string
       GetStartCell() string
   }

   // ✅
   type RangeInfo interface {
       SheetName() string
       StartCell() string
   }
   ```

4. **Rename proto imports at the import site**, consistently everywhere:

   ```go
   complaintpb "myservice/gen/complaint_analysis"  // drops the underscore, marks it generated
   ```

5. **Fix it at the IDL when you can.** If you own the `.proto`, the cleanest fix is naming
   fields so generated code comes out right — but protoc-gen-go will still emit `HeroId`
   for `hero_id` (it doesn't know `id` is an initialism), so the mapper firewall stays
   necessary regardless. Some teams add a lint step that rejects `Id`/`Url` outside
   `gen/` and mapper files.

## Review signal

When you see `SourceUrl: item.SourceURL` — both casings on one line — that's not a bug,
that's the firewall doing its job. When you see `item.SourceUrl` in hand-written domain
code with no proto in sight, the firewall has been breached: fix the domain type and let
the mapper absorb the mismatch.
