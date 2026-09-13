# curam — Work Diagrams

Mermaid diagrams for the curam design. Render on GitHub, VSCode (Mermaid
Preview), or `docs/curam.md`'s adjacent tooling. Updated for the POC-first
(Python) plan and the SLO/SLI framework.

## 1. Architecture Overview — POC (Python)

The session journal is the hub. Everything reads from it; nothing writes back
except the agent loop itself. SLOs are SQL views over the journal.

```mermaid
flowchart LR
    subgraph poc["curam POC (Python) · single process"]
        LOOP["agent loop<br/>(messages → provider → tools → repeat)"]
        TOOLS["tools<br/>read / write / edit / shell"]
        ASK["ask layer<br/>(judgment + approvals)"]
        POL["policy<br/>stage-1 deterministic"]
        JUDGE["classifier<br/>stage-2 local LLM judge"]
        JOURNAL[("SQLite · WAL journal<br/>source of truth (audit + cost)")]
    end

    USER["you"] -->|REPL + Textual UI| LOOP
    LOOP -->|tool_call| TOOLS
    TOOLS -->|args| POL
    POL -->|uncertain| JUDGE
    POL -->|allow / ask / deny| ASK
    JUDGE -->|"injection / credential / destructive"| ASK
    ASK -->|"waiting"| USER
    TOOLS -->|tool_result| JOURNAL
    POL -->|deny| JOURNAL
    LOOP -->|model request + usage| JOURNAL
    LOOP -->|"prompt + context"| LITELLM["LiteLLM (local)<br/>→ Ollama / vLLM / cloud"]
    LITELLM -->|"completion + usage"| LOOP

    subgraph ui["Textual UI (reader)"]
        UI["model · reasoning effort · context fill<br/>session cost · budget left · live stream"]
    end
    JOURNAL --> UI
```

## 2. Tool-Call Path (Classifier + Ask)

Two-tier classification: deterministic arg-array policy on every call, tiny
local LLM judge only on the uncertain remainder. Asks are for *judgment*, not
just permission.

```mermaid
flowchart TD
    A["model emits tool_call<br/>{name, args}"] --> B["journal: tool_call"]
    B --> C{"stage-1 · deterministic<br/>arg-array policy (fast)"}
    C -->|deny| D["journal: tool_denied"]
    D --> F["result returned to model"]
    C -->|allow| J["exec gate<br/>cwd = project workdir<br/>shell = raw subprocess (POC)"]
    C -->|uncertain| E{"stage-2 · local LLM judge<br/>injection / credential / destructive?"}
    E -->|benign| J
    E -->|flagged| G["journal: ask_human"]
    C -->|ask| G
    G --> H{"human decision"}
    H -->|grant| I["journal: human_answer"]
    H -->|deny| D
    I --> J
    J --> K["subprocess / file ops"]
    K --> L["capture stdout/stderr/exit"]
    L --> M["journal: tool_result"]
    M --> F
    F --> N["model continues"]
```

## 3. Session Lifecycle (Event States)

```mermaid
stateDiagram-v2
    [*] --> idle: curam start
    idle --> running: user_message
    running --> awaiting_judgment: ask_human
    awaiting_judgment --> running: human_answer
    running --> awaiting_approval: approval_requested
    awaiting_approval --> running: approval_granted
    awaiting_approval --> running: tool_denied
    running --> running: model_message / tool_result / cost / error
    running --> idle: user_message (new turn)
    idle --> [*]: exit
```

## 4. What We Build Now vs Later

POC (Python, throwaway) proves the risky bits; the journal schema and SLOs
survive into the Rust rewrite.

```mermaid
flowchart LR
    subgraph poc["POC (Phase 0) — Python, ordered by risk"]
        P1["agent + raw shell"]
        P2["ask layer (judgment, then approvals)"]
        P3["two-stage classifier"]
        P4["SQLite WAL journal + budget"]
        P5["Textual UI (model · context · cost)"]
    end

    subgraph slo["SLOs — the gate"]
        S1["Go/No-Go: 10 north-star SLOs"]
        S2["watch SLIs + error budgets"]
        S3["fixed task corpus (benign + red-team + traps)"]
    end

    subgraph v1["Rust rewrite (only if SLOs pass)"]
        R1["typed run tool · no free-text shell"]
        R2["bwrap / systemd-run cage"]
        R3["event loop (tokio) · one provider impl"]
    end

    subgraph later["Later — readers & cages"]
        L1["nushell (structured output)"]
        L2["wasmtime extension tier"]
        L3["OTel → Arize"]
        L4["Matrix phone bridge"]
        L5["supervisor workers"]
        L6["pi-extension shim (deno)"]
    end

    P1 --> P2 --> P3 --> P4 --> P5
    P5 -.->|"measures"| S1
    S3 -.->|"feeds"| S1
    S1 -->|"pass"| R1
    S1 -.->|"fail = fix what the number says"| P2
    R1 --> R2
    R1 -.-> R3
    R2 -.-> L1
    R3 -.-> L2
    R1 -.->|"M2"| L3
    R1 -.->|"M3"| L4
    R1 -.->|"M4"| L5
    R1 -.->|"optional"| L6
```

## 5. SLO Feedback Loop

The journal is the instrument; every SLI is one SQL view over it; the
dashboard and error budgets read the same views.

```mermaid
flowchart LR
    J[("SQLite · WAL journal<br/>every event transactional")]
    V["SLI views (SQL)<br/>N1–N10 + watch bands"]
    D[("dashboard<br/>Textual panel + curam sli")]
    S["SLOs / error budgets"]

    J -->|"event stream"| V
    V -->|"thresholds"| S
    V -->|"live numbers"| D
    S -->|"breach → tune ask triggers / fix mechanism"| J

    subgraph gate["Go/No-Go gate"]
        S -->|"N1–N10 met + 5 real sessions"| R["Rust rewrite"]
        S -->|"miss → fix what the number says"| F["stay in POC"]
    end
```
