# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

OfficeAgent DevOps/AIOps 채용 과제 — **멀티 환경 배포 설계 (NHN·오픈스택 등 규제 대응)**. OfficeAgent를 정부·공공기관 고객의 규제 요건에 맞춰 AWS·NHN 클라우드·오픈스택 온프레미스 등 여러 환경에 배포 가능하도록 설계하고 발표하는 과제 리포지토리.

## 핵심 요구사항

1. **마이그레이션 설계서 (`MIGRATION_PLAN.md`)** — 5개 도메인(네트워크·데이터·컴퓨트·관측·비용) 중 **2개를 깊이 분석**, 나머지는 매핑 수준
2. **추상화 설계 (`ARCHITECTURE.md`)** — NHN/오픈스택 둘 다 대응 가능한 분리 설계 (다이어그램·모듈)
3. **검증 산출물 (`VALIDATION.md` 또는 MIGRATION_PLAN §6)** — 깊이 다룬 도메인 2개에 각 1개 이상의 시나리오. 형태 자유(IaC skeleton·리허설·SQL·runbook·비용 표 등). 입력·명령·기대 출력·실패 판단 기준 필수.
4. **발표 자료 (`deck/`)** — 30분 발표 + 30분 Q&A. 핵심 의사결정 3~5개 트레이드오프 표
5. **회고 (`retros/`)** — Retrobot 자동 생성 또는 수동 학습 일지

## 기술 조건

- **IaC 도구**: 자유 (Terraform / OpenTofu / Pulumi / Crossplane / Ansible 등). NHN+오픈스택 둘 다 대응 가능한 구조 입증 필요
- **클라우드 계정**: 불필요 (실 apply 없음, 설계 + 선택적 plan/dry-run으로 충분)
- **LLM SDK**: 선택 PoC용. `claude-code-sdk` 또는 `@openai/codex` 등 — 미사용 가능. AI 도구가 없으면 수동 `retros/` 작성으로 동등 평가
- **AI 도구 부재 시**: 수동 `retros/*.md` 학습 일지로 대체 가능 (평가 불이익 없음)

## 필수 산출물

- `MIGRATION_PLAN.md` — 마이그레이션 설계서 (`MIGRATION_PLAN.template.md` 기반)
- `ARCHITECTURE.md` — 추상화 설계 (`ARCHITECTURE.template.md` 기반)
- `VALIDATION.md` (또는 MIGRATION_PLAN §6 검증 계획) — 검증 산출물 (`VALIDATION.template.md` 기반)
- `deck/` 안의 발표 자료 (PDF/Keynote/Markdown deck 자유)
- `retros/` 안의 회고 또는 학습 일지

## 선택 산출물 (§1.3 검증 점수의 근거 보강)

별도 가산점이 아니라, §1.3 구현·검증 가능성 점수의 근거를 풍부하게 하는 선택 증거다.

- `infra/` — IaC PoC
- `runbooks/`, `scripts/` — 운영 자동화·AIOps PoC (알람 진단, 드리프트 비교, 비용 이상치 감지 등)

## 별첨 AWS 스펙

`docs/PRD.md` §부록의 **가상 AWS 스펙 골격**을 출발점으로 합니다. VPC + ALB + ECS Fargate + RDS PostgreSQL + S3 + ElastiCache Redis + CloudWatch + IAM + GitHub Actions 수준. 가상 트래픽·CSAP 컴플라이언스·4시간 다운타임 제약이 명시되어 있습니다.

## AI 에이전트 — Claude Code 권장

이 과제는 **Claude Code 사용을 권장**하되 Codex CLI·Gemini CLI 등 다른 에이전트도 사용 가능하다. 규칙·스킬·훅 컨버팅 상세는 [`docs/AGENT_SETUP.md`](./docs/AGENT_SETUP.md) 참조.

- `CLAUDE.md` (이 파일) — Claude Code 자동 인식
- `AGENTS.md` — `CLAUDE.md`의 심볼릭 링크. Codex 자동 인식
- `GEMINI.md` — `CLAUDE.md`의 심볼릭 링크. Gemini CLI 자동 인식
- 세 파일은 같은 내용. 한쪽만 수정해도 심볼릭 링크라 동기화됨

## Retrobot (자동 회고)

- `retrobot/SKILL.md` — AI 에이전트가 읽고 실행하는 KPT 회고 생성 지침
- `.githooks/post-commit` — 커밋 후 `claude` → `codex` → `gemini` 순으로 가용 CLI 호출 (자동 폴백)
- 커밋 메시지에 "Retrobot"이 포함되면 훅 스킵 (무한 루프 방지)
- 회고는 `retros/` 디렉토리에 저장되고 자동 커밋

### 설정

```bash
git config core.hooksPath .githooks
```

### 수동 실행 (AI 도구 가용 시)

```bash
claude -p "$(cat retrobot/SKILL.md)"                      # Claude Code (권장)
cat retrobot/SKILL.md | codex exec --sandbox workspace-write   # Codex (stdin 파이프)
gemini -p "$(cat retrobot/SKILL.md)"                      # Gemini CLI
```

## 평가 비중 — 3축 매핑

| 평가 능력 | 영역 | 비중 |
|----------|------|-----:|
| **아키텍처 설계능력** | 마이그레이션 설계 · 의사결정 | 30% |
| **아키텍처 설계능력** | 멀티 환경 추상화 | 20% |
| **구현 및 검증능력** | 구현 · 검증 가능성 (§1.3 검증 산출물의 재현성·구체성) | 20% |
| **잘 모르는 분야 학습능력** | 조사 · 학습 깊이 (1차 자료, 미지 영역 분해, 학습 후 설계 변경) | 20% |
| (보조 — 위 3축 검증 수단) | 발표 · 소통 (30분 Q&A 응답 깊이, 미해결 위험 솔직성) | 10% |

**Track C (학습 궤적, 20점)**은 별도 보조 지표 — 60~75점 경계 후보의 우선순위 카드.

**완성도보다 의사결정·조사 흔적이 우선.** 단, **핵심 결정**(본인이 깊이 다루기로 한 도메인)에는 잠정 결론과 검증 계획이 필요합니다 — 단순 "후속 조사 필요"는 감점.

## LLM Wiki 활용 규칙

이 프로젝트는 `wiki/` 디렉토리에 `[[wiki-link]]` 교차참조 위키를 유지한다. Karpathy LLM Wiki 패턴을 따른다.

### 작업 시 우선순위

1. **위키 우선 참조**: 질문에 답하거나 작업을 시작할 때, `wiki/index.md`에서 관련 페이지를 먼저 찾아 읽는다. `[[wiki-link]]`를 따라 2-hop까지 확장하여 맥락을 파악한다.
2. **출처 인용**: 답변 작성 시 위키 페이지를 `[[페이지 제목]]` 형태로 인용한다.
3. **위키에 없으면 명시**: 위키에 답이 없으면 "위키에 없음"이라 표기하고 `wiki/raw/` 또는 외부 원본을 읽어 보강한다. 새 내용이면 `llm-wiki ingest`로 위키를 성장시킨다.
4. **검색보다 컴파일**: 매번 원본을 다시 읽지 말고, 이미 컴파일된 위키 지식을 적극 재활용한다.
5. **최신성 재확인**: 위키 페이지는 조사 시점 스냅샷이다. 규제·인증 요건(CSAP 등급·법령·NHN 서비스)은 변동되므로, 설계를 확정하기 전 공식 1차 자료(NHN docs·KISA 고시·법령 원문)로 최신성을 반드시 재확인한다. `wiki/raw/`는 1차 자료가 아닌 초기 조사 메모다.

### 위키 구조

- `wiki/index.md` — 자동 재빌드되는 라우팅 레이어 (수동 편집 금지)
- `wiki/{page}.md` — 컴파일된 지식 페이지 (`[[wiki-link]]` 교차참조)
- `wiki/raw/` — 원본 소스 드롭존 (불변)
- `wiki/log.md` — ingest 이력
- `wiki/.lancedb/` — 선택적 벡터 인덱스 (lancedb-sync 실행 시)

### 스킬 명령

사용자가 `llm-wiki <command>`를 호출하면 해당 단계 실행:
- `init` — 구조 초기화
- `ingest <source>` — 새 소스를 컴파일해 위키 갱신
- `query <질문>` — 하이브리드 검색(qmd) 또는 INDEX.md 라우팅
- `lint` — 끊어진 링크·고아 페이지 탐지
- `sync` — index.md 재빌드
- `export <template>` — 온보딩·ADR 요약 등 출력
- `qmd-index` — qmd 인덱스 빌드 (선택)
- `lancedb-sync` — LanceDB 벡터 인덱스 동기화 (선택)
