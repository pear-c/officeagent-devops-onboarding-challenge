# AI 에이전트 설정 가이드

이 과제는 **Claude Code 사용을 권장**합니다. 단, Codex CLI·Gemini CLI 등 다른 에이전트를 쓰셔도 됩니다 — **어떤 에이전트를 쓰든 평가상 불이익은 없습니다.** 본 문서는 다른 에이전트를 쓸 때 이 템플릿의 **규칙·스킬·훅**을 어떻게 컨버팅하는지 안내합니다.

> 평가의 핵심은 "어떤 도구를 썼는가"가 아니라 "AI를 도구로 얼마나 잘 다뤘고 그 과정에서 얼마나 학습했는가"입니다 (PRD §0 메타 목표).

---

## 0. 왜 Claude Code를 권장하는가

- 이 템플릿의 자산(규칙 파일, Retrobot 스킬, post-commit 훅)이 Claude Code 기준으로 1차 작성되어 **추가 컨버팅 없이 바로 동작**합니다.
- NextIntelligence 팀의 표준 워크플로가 Claude Code 기반입니다 — 입사 후 온보딩이 매끄럽습니다.
- 그러나 **강제는 아닙니다.** 아래 컨버팅 표를 따르면 Codex·Gemini로도 동등하게 진행할 수 있습니다.

---

## 1. 자산별 컨버팅 표

| 자산 | 파일 | Claude Code (권장) | Codex CLI | Gemini CLI | 기타 에이전트 |
|------|------|--------------------|-----------|------------|---------------|
| **규칙** (프로젝트 지침) | `CLAUDE.md` | 자동 인식 | `AGENTS.md` 자동 인식 (`CLAUDE.md` 심볼릭 링크) | `GEMINI.md` 자동 인식 (`CLAUDE.md` 심볼릭 링크) | `AGENTS.md`를 컨텍스트/시스템 프롬프트로 직접 주입 |
| **스킬** (Retrobot 회고) | `retrobot/SKILL.md` | `Skill` 도구로 호출 또는 `claude -p "$(cat retrobot/SKILL.md)"` | `cat retrobot/SKILL.md \| codex exec --sandbox workspace-write` | `gemini -p "$(cat retrobot/SKILL.md)"` | `SKILL.md` 본문을 프롬프트로 전달 + 파일 쓰기 권한 부여 |
| **훅** (자동 회고 트리거) | `.githooks/post-commit` | `claude` 분기 자동 실행 | `codex` 분기 자동 실행 | `gemini` 분기 자동 실행 | 훅 안에 본인 에이전트 CLI 분기를 추가 (아래 §4) |

세 자산 모두 **이미 컨버팅이 끝나 있습니다** — `AGENTS.md`·`GEMINI.md` 심볼릭 링크가 존재하고, `.githooks/post-commit`이 claude·codex·gemini 3종을 자동 폴백합니다. 표는 "내부적으로 어떻게 동작하는지"의 설명입니다.

---

## 2. 규칙 파일 (CLAUDE.md / AGENTS.md / GEMINI.md)

세 파일은 **같은 내용**입니다 (`AGENTS.md`·`GEMINI.md`는 `CLAUDE.md`의 심볼릭 링크).

- **Claude Code**: `CLAUDE.md`를 세션 시작 시 자동으로 읽습니다.
- **Codex**: `AGENTS.md`를 자동으로 읽습니다.
- **Gemini CLI**: `GEMINI.md`를 자동으로 읽습니다.
- **기타 에이전트**: 자동 인식이 없으면 `AGENTS.md` 내용을 첫 프롬프트나 시스템 메시지에 직접 붙여 넣으세요.

> 심볼릭 링크가 깨진 환경(일부 Windows·zip 다운로드)이라면 `cp CLAUDE.md AGENTS.md` / `cp CLAUDE.md GEMINI.md`로 실제 파일을 복제하세요. 단 한쪽을 수정하면 다른 쪽도 직접 맞춰야 합니다.

---

## 3. 스킬 (retrobot/SKILL.md)

`retrobot/SKILL.md`는 Claude Code Skill 형식이지만, **본질은 "회고를 생성하라"는 지침 문서**입니다. 어떤 에이전트든 이 파일 본문을 프롬프트로 전달하면 동작합니다.

```bash
# Claude Code — Skill 도구 또는 -p 플래그
claude -p "$(cat retrobot/SKILL.md)"

# Codex — stdin 파이프 (argv 방식은 stdin EOF로 hang 위험)
cat retrobot/SKILL.md | codex exec --sandbox workspace-write

# Gemini CLI — -p 플래그
gemini -p "$(cat retrobot/SKILL.md)"
```

핵심: 에이전트에게 **파일 읽기·쓰기 권한**이 있어야 합니다 (회고를 `retros/`에 써야 하므로). Codex는 `--sandbox workspace-write`, Claude Code는 `--allowedTools`로 부여합니다.

---

## 4. 훅 (.githooks/post-commit)

`git config core.hooksPath .githooks` 설정 후, `git commit`마다 `.githooks/post-commit`이 실행되어 회고를 자동 생성합니다.

훅은 **claude → codex → gemini 순으로 자동 폴백**합니다. 셋 다 없으면 건너뛰고 수동 회고를 안내합니다.

### 본인 에이전트가 목록에 없다면

`.githooks/post-commit`의 분기 블록에 한 줄을 추가하세요:

```bash
elif command -v <your-agent> >/dev/null 2>&1; then
    <your-agent> <비대화형-실행-플래그> "$(cat $SKILL_PATH)" 2>/dev/null
```

이렇게 훅을 본인 도구에 맞게 수정한 것 자체가 **구현·검증능력의 시그널**입니다 — retros나 커밋 메시지에 남겨 두세요.

### 훅을 아예 안 쓰고 싶다면

`git config --unset core.hooksPath`로 비활성화하고, 대신 `retros/YYYY-MM-DD.md` 학습 일지를 **수동 작성**하세요. PRD §1.5 기준 평가상 동등합니다.

---

## 5. AI 도구가 아예 없다면

유료 AI 구독·CLI가 전혀 없어도 과제 진행이 가능합니다.

- 규칙: `AGENTS.md`를 직접 읽고 따릅니다.
- 스킬·훅: 비활성화하고 `retros/*.md`를 손으로 작성합니다.
- 평가: PRD §1.5 · §기술 조건에 따라 **수동 학습 일지도 동등하게 평가**됩니다.

단, 이 과제의 메타 목표가 "바이브 코딩으로 마이그레이션을 해낼 수 있는가"이므로, **가능하면 AI 도구를 쓰고 그 과정을 retros에 남기는 것**을 강력히 권장합니다.

---

## 6. 컨버팅 작업 자체가 평가 대상

다른 에이전트를 쓰기 위해 규칙·스킬·훅을 컨버팅한 과정은 그 자체로 **"낯선 환경을 본인에 맞게 길들이는 능력"**의 증거입니다. 컨버팅하면서 부딪힌 문제·해결을 `retros/`에 기록하면 §4 조사·학습 깊이 / Track C에서 가산됩니다.
