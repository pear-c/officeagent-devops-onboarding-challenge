# 템플릿 사용 가이드

이 문서는 본 템플릿을 처음 받은 후 어떻게 시작하면 좋은지 안내합니다. PRD([`PRD.md`](./PRD.md))를 먼저 읽은 다음 본 가이드를 참고하세요.

## 1. 첫 30분 — 환경 셋업

```bash
# 1. Use this template으로 본인 계정에 Private 리포 생성
# 2. 클론 후 Retrobot 활성화
git clone <your-private-repo-url>
cd <repo-name>
git config core.hooksPath .githooks

# 3. (선택) Claude Code / Codex CLI 가용성 확인
claude --version 2>/dev/null || echo "Claude Code 미설치"
codex --version 2>/dev/null || echo "Codex CLI 미설치"
```

AI 도구가 둘 다 없어도 진행 가능합니다. `retros/` 디렉토리에 수동으로 KPT 일지(`YYYY-MM-DD.md`)를 작성하시면 동등하게 평가합니다.

## 2. 첫 2일 — 조사 + 도메인 2개 결정

### 먼저: 공공 규제 LLM Wiki를 읽으세요

이 리포에는 한국 공공·정부기관 클라우드 도입 규제가 **`wiki/` 디렉토리에 LLM Wiki로 구조화**되어 있습니다. `wiki/index.md`를 진입점으로 시작하세요.

- CSAP·망분리·데이터 주권·ISMS·NHN Cloud·오픈스택·정책 동향 등 10개 페이지
- 각 페이지는 `[[wiki-link]]` 교차참조 + 1차 자료 출처
- `wiki/migration-checklist.md`는 설계 시 점검 항목
- AI 에이전트를 쓴다면 `CLAUDE.md` §"LLM Wiki 활용 규칙"이 wiki 우선 참조를 지시합니다

> **wiki는 출발점입니다.** 평가의 핵심은 wiki를 기반으로 1차 자료(NHN docs·KISA 고시·법령·OpenStack docs)까지 직접 파고드는 것입니다. wiki를 그대로 베끼면 평가되지 않습니다. 조사하며 새로 알게 된 내용을 wiki에 추가(`llm-wiki ingest` 또는 수동으로 `wiki/`에 페이지 작성)하면 §4 조사·학습 / Track C에서 긍정 평가됩니다.
>
> `llm-wiki` 스킬이 없는 환경이라면 `wiki/`를 일반 마크다운 디렉토리로 읽고, 확장은 `wiki/`에 페이지를 직접 추가하면 됩니다 (스킬 없이도 동작).

### 도메인 2개 결정

PRD §1.1의 5개 도메인 중 **본인이 깊이 분석할 2개**를 먼저 결정하세요:

| 도메인 | 깊이 분석 시 기대 | 관련 wiki |
|--------|------------------|-----------|
| A. 네트워크 / 보안 | VPC↔NHN VPC, NAT 등가, IAM↔NHN 권한, CSAP 망분리 | `wiki/network-isolation.md` |
| B. 데이터 / 스토리지 | RDS↔NHN DB, S3↔Object Storage, 이전 단계·일관성 검증 | `wiki/data-sovereignty.md` |
| C. 컴퓨트 / 배포 | ECS Fargate↔NHN K8s/VM, 배포 파이프라인, 롤백 | `wiki/nhn-cloud.md` |
| D. 운영·관측 / AIOps | CloudWatch↔NHN 모니터링, AIOps 자동화 | `wiki/policy-trends.md` |
| E. 비용 / 규제 | 비용 정량 비교, CSAP·데이터 주권·계열사 정책 | `wiki/csap.md` |

**선택 기준 힌트** — 본인이 이미 익숙한 영역 1개 + 도전적인 영역 1개를 섞으면 학습 궤적이 잘 드러납니다.

이 시점부터 1차 자료를 적극적으로 인용하세요 (wiki 각 페이지의 "1차 자료" 섹션도 출발점):
- NHN Cloud docs: <https://docs.nhncloud.com/>
- CSAP 인증 가이드: KISA 또는 정보보호평가센터 자료
- 오픈스택 docs: <https://docs.openstack.org/>

## 3. 3~8일 — 설계서·아키텍처 작성

- `MIGRATION_PLAN.template.md` → `MIGRATION_PLAN.md`로 복사 후 채우기
- `ARCHITECTURE.template.md` → `ARCHITECTURE.md`로 복사 후 채우기
- 다이어그램: mermaid (리포에 직접) / draw.io (이미지 export) / Excalidraw / 손그림 스캔 자유
- "모른다"고 적을 영역은 **리스크 + 검증 계획**을 함께 적기 (단순 미답은 감점)

## 4. 9~10일 — 검증 산출물 작성 (PRD §1.3, 필수)

PRD가 새로 강조하는 평가 축입니다 — **"이 검증을 실제로 실행한다면 입력·명령·기대 출력·실패 시 판단 기준이 명확한가"**가 발표 Q&A 3번 축에서 확인됩니다.

- `VALIDATION.template.md` → `VALIDATION.md`로 복사 후 채우기 **또는** `MIGRATION_PLAN.md`의 §6 검증 계획 섹션에 통합
- 깊이 다룬 도메인 2개 각각에 **최소 1개 이상**의 시나리오
- 형태 자유 (택 1 이상): IaC skeleton + `validate` 통과 / 리허설 체크리스트 / 데이터 무결성 SQL / Object Storage sync 절차 / 알람 진단 runbook / 롤백 시나리오 / 비용 산정 표 / 메트릭 검증 정의
- 짧아도 좋습니다. 도메인당 시나리오 2~3개면 충분.
- (선택) `infra/` 디렉토리에 IaC PoC 확장. `runbooks/`·`scripts/`·`observability/`도 §1.3 구현·검증 가능성 점수의 근거가 됩니다 (별도 가산점이 아니라 검증 증거).

## 5. 11~13일 — 발표 자료 작성

- `deck/` 디렉토리에 PDF/Keynote/Markdown deck (자유 형식)
- 핵심 의사결정 3~5개를 트레이드오프 표로 정리
- 가장 큰 미해결 위험 1~2개를 솔직히 명시 (감점 아닌 가산)
- 30분 발표 + 30분 Q&A 분량 가정

## 6. 마감일 (2026-05-31) — 제출

- 리포 모든 산출물 커밋 + push
- [`serithemage`](https://github.com/serithemage)를 Collaborator로 초대
- 마감: 2026-05-31 23:59 KST

## 7. 제출 후 — 발표 세션

- 제출 마감 후 7일 이내 화상회의
- 30분 발표 + 30분 Q&A
- 평가자 2인 (엔지니어링 리드 + 시니어 멘토) 동석
- 표준 시작 질문: *"본인이 깊이 다룬 2개 도메인 중 가장 큰 미해결 위험 1개와 그 근거"*
- **Q&A 6축 중 3번 "검증 리허설"**: §1.3 검증 산출물 하나를 골라 "실제 실행 시 입력·명령·기대 출력·실패 판단 기준"을 말로 풀어 설명해야 함. 미리 자료의 부록 슬라이드에 한 시나리오 정도 풀어두면 좋습니다.

## 자주 묻는 질문

**Q. 5개 도메인 다 다뤄야 하나요?**
아니오. 2개를 깊이, 나머지는 매핑·미해결 가정 수준이면 OK. 좁고 깊게가 더 높이 평가됩니다.

**Q. IaC 코드는 꼭 작성해야 하나요?**
완성형 IaC는 필수가 아닙니다. 단 **§1.3 검증 산출물은 필수** — 코드형(IaC skeleton + validate)도, 문서형(리허설 체크리스트·검증 쿼리·runbook)도 동등 평가입니다.

**Q. NHN 계정이 필요한가요?**
불필요. 실 apply 없음. `validate` / `plan` / `dry-run` 같은 로컬 검증 산출물로 충분.

**Q. AI 도구가 없으면 불리한가요?**
아니오. 수동 학습 일지로 대체 가능. 평가 불이익 없음.
