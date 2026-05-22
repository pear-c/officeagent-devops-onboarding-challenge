# OfficeAgent DevOps/AIOps 채용 과제 — 멀티 환경 배포 설계 (NHN·오픈스택 등 규제 대응)

> **이 과제가 진짜로 묻는 것**: *"바이브 코딩과 AI 기반 학습을 도구로 다뤄, 본인이 익숙하지 않은 영역(NHN·CSAP·오픈스택·정부기관 납품 요건)의 멀티 환경 배포 설계를 실제로 해낼 수 있는 사람인가."*
>
> AI 사용을 숨기지 마세요 — 오히려 명시적으로 드러내는 것이 강한 시그널입니다. retros/ 안의 프롬프트·시행착오·복구가 1순위 평가 사료입니다.

## 시작하기

이 리포지토리를 **Use this template**으로 복사한 후, 아래 PRD에 따라 과제를 진행하세요.

[![Use this template](https://img.shields.io/badge/Use_this_template-238636?style=for-the-badge&logo=github&logoColor=white)](https://github.com/roboco-io/officeagent-devops-onboarding-challenge/generate)

GitHub 로그인 상태에서 위 버튼을 누르면 "Create a new repository from officeagent-devops-onboarding-challenge" 페이지로 바로 이동합니다.

## 과제 내용

**[PRD 바로가기 →](./docs/PRD.md)**

OfficeAgent를 NHN 클라우드·오픈스택 온프레미스 등 고객 규제 대응 환경에도 배포 가능하도록 하는 **멀티 환경 배포 설계서 + 발표 세션**을 작성합니다. 코드 구현은 선택이며 PoC 수준으로 충분합니다.

### 평가 역량 — 3축 매핑

| 평가 능력 | 채점 영역 | 비중 |
|----------|----------|-----:|
| **아키텍처 설계능력** | 마이그레이션 설계 + 멀티 환경 추상화 | 30% + 20% = **50%** |
| **구현 및 검증능력** | 구현 · 검증 가능성 (`VALIDATION.md` 또는 MIGRATION_PLAN §검증) | **20%** |
| **잘 모르는 분야 학습능력** | 조사 · 학습 깊이 (+ Track C 20점 보조) | **20%** |
| (보조) 발표 · 소통 | 30분 Q&A에서 위 3축 검증 수단 | **10%** |

> **Track C (학습 궤적, 20점)**는 위 100점에 합산되지 않습니다 — Track A 60~75점 경계 후보의 합격/조건부를 가르는 보조 지표입니다.

### 기술 스택

- **IaC 도구:** 자유 (Terraform / OpenTofu / Pulumi / Crossplane / Ansible 등). NHN+오픈스택 둘 다 대응 가능한 구조 입증이 필요.
- **클라우드 계정:** 불필요 (실 apply 없음, 설계 + 선택적 plan/dry-run으로 충분)
- **LLM (선택 PoC용):** Claude Code SDK 또는 Codex CLI

### 5개 도메인 중 2개를 깊이

PRD §1.1의 5개 도메인 (네트워크·데이터·컴퓨트·관측·비용) 중 **2개를 정해 깊이 분석**하고 나머지는 매핑·미해결 가정 수준으로 다룹니다. **넓고 얕게보다 좁고 깊게**가 더 높이 평가됩니다.

## AI 에이전트 설정 — Claude Code 권장

이 과제는 **Claude Code 사용을 권장**합니다. 템플릿의 규칙·스킬·훅이 Claude Code 기준으로 작성되어 추가 설정 없이 바로 동작하고, 입사 후 팀 표준 워크플로와 일치하기 때문입니다.

**Codex CLI·Gemini CLI 등 다른 에이전트도 사용 가능**하며 평가상 불이익이 없습니다. 다른 에이전트를 쓸 때 규칙·스킬·훅을 어떻게 컨버팅하는지는 **[`docs/AGENT_SETUP.md`](./docs/AGENT_SETUP.md)** 에 정리되어 있습니다.

| 자산 | Claude Code | Codex | Gemini |
|------|-------------|-------|--------|
| 규칙 | `CLAUDE.md` (자동) | `AGENTS.md` (자동, 심볼릭 링크) | `GEMINI.md` (자동, 심볼릭 링크) |
| 스킬 | `Skill` 또는 `claude -p` | `cat … \| codex exec` | `gemini -p` |
| 훅 | `.githooks/post-commit` claude 분기 | codex 분기 | gemini 분기 |

`.githooks/post-commit`은 claude → codex → gemini 순으로 자동 폴백합니다.

## 공공 규제 LLM Wiki — `wiki/`

한국 공공·정부기관 클라우드 도입 규제(CSAP·망분리·데이터 주권·ISMS·NHN Cloud·오픈스택·정책 동향)가 **`wiki/` 디렉토리에 LLM Wiki로 구조화**되어 있습니다.

- **`wiki/index.md`를 진입점**으로 시작하세요. 10개 페이지가 `[[wiki-link]]`로 교차참조됩니다.
- `wiki/migration-checklist.md` — 설계 시 점검 항목
- `wiki/raw/` — Perplexity **초기 조사** 원자료 (출처 보존). ※ 초기 조사 메모이지 1차 자료가 아님 — 1차 자료는 NHN docs·KISA 고시·법령·OpenStack docs
- **wiki는 출발점**입니다. 평가의 핵심은 wiki를 기반으로 1차 자료까지 직접 파고드는 것 — 그대로 베끼면 평가되지 않습니다.
- 조사하며 새로 알게 된 내용을 wiki에 추가하면 §4 조사·학습 / Track C에서 긍정 평가 (필수 아님). `CLAUDE.md` §"LLM Wiki 활용 규칙" 참조.

## Retrobot — 자동 회고

이 프로젝트에는 [Retrobot](./retrobot/README.md)이 포함되어 있습니다. `git commit`할 때마다 AI 에이전트(Claude Code 권장 / Codex / Gemini) 작업 로그를 분석하여 KPT 회고를 자동 생성합니다.

**초기 설정 (리포지토리 생성 후 1회):**

```bash
git config core.hooksPath .githooks
```

> 유료 AI 구독(Claude Pro/Max·ChatGPT Pro·Gemini 등)이 없는 경우 수동으로 `retros/YYYY-MM-DD.md` 학습 일지를 작성하셔도 평가 불이익 없습니다. PRD §기술 조건 참조.

## 디렉토리 구조

```
.
├── docs/
│   ├── PRD.md                     # 과제 PRD (요구사항·5영역 채점표·2026-05-31 23:59 KST 마감)
│   ├── TEMPLATE_GUIDE.md          # 본 템플릿 사용 가이드 (선택형 깊이 + 검증 산출물 안내)
│   └── AGENT_SETUP.md             # AI 에이전트 컨버팅 가이드 (Claude/Codex/Gemini)
├── wiki/                          # 공공 규제 LLM Wiki — index.md 진입, 10개 페이지
│   ├── index.md                   #   자동 라우팅 레이어
│   ├── csap.md, network-isolation.md, ...  #   교차참조 지식 페이지
│   └── raw/                       #   Perplexity 초기 조사 원자료 (1차 자료 아님)
├── MIGRATION_PLAN.template.md     # 마이그레이션 설계서 + §6 검증 계획 → MIGRATION_PLAN.md
├── ARCHITECTURE.template.md       # 추상화 설계 → ARCHITECTURE.md
├── VALIDATION.template.md         # 검증 산출물 (PRD §1.3, 필수) → VALIDATION.md
│                                  #   ※ MIGRATION_PLAN §6에 통합해도 동등
├── deck/                          # 발표 자료 (PDF/Keynote/Markdown deck 자유)
├── retros/                        # Retrobot 또는 수동 학습 일지
├── infra/                         # (선택) IaC PoC 확장
├── runbooks/                      # (선택) 운영 자동화·AIOps PoC
├── scripts/                       # (선택) 검증 스크립트
├── observability/                 # (선택) 메트릭/로그 대시보드 정의
├── .githooks/                     # Retrobot post-commit 훅
└── retrobot/                      # Retrobot 스킬 정의
```

## 제출 방법

1. 아래 버튼 클릭, 또는 우측 상단 **"Use this template"** → **"Create a new repository"**:

   [![Use this template](https://img.shields.io/badge/Use_this_template-238636?style=for-the-badge&logo=github&logoColor=white)](https://github.com/roboco-io/officeagent-devops-onboarding-challenge/generate)
2. Owner를 본인 계정으로, **Private** 리포지토리로 생성
3. `git config core.hooksPath .githooks` 실행 (Retrobot 활성화)
4. PRD에 따라 과제 진행
5. [`serithemage`](https://github.com/serithemage)를 Collaborator로 초대

**기한:** 2026-05-31 (일) 23:59 KST
**발표 세션:** 제출 마감 후 7일 이내, 30분 발표 + 30분 Q&A

자세한 내용은 [PRD](./docs/PRD.md) · [본 템플릿 가이드](./docs/TEMPLATE_GUIDE.md)를 참고하세요.
