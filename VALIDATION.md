# 검증 산출물 — OfficeAgent 멀티 환경 마이그레이션

> 깊이 도메인 **A. 네트워크/보안** · **B. 데이터/스토리지** 각각에 대한 검증 시나리오.
> 모든 시나리오는 **입력 / 명령 / 기대 출력(구체값) / 실패 시 판단 기준** 4종을 명시한다 (PRD §1.3, 발표 Q&A 3번 축).
> 설계 근거·1차 자료는 [`MIGRATION_PLAN.md`](./MIGRATION_PLAN.md) 참조.
>
> ⚠️ 실 apply·실 클라우드 계정 없음(PRD §3). 본 문서는 **리허설 절차 + 기대 출력 정의**다. `terraform validate`처럼 로컬 실행 가능한 것은 명령을 그대로, 실 인프라가 필요한 것은 "실행 시점·기대 출력"을 명세한다.

---

## 0. 검증 산출물 개요

| 도메인 | 시나리오 | 형태 |
|--------|---------|------|
| **A 네트워크/보안** | A-1 네트워크 IaC validate + SG 흐름 정적 검증 / A-2 CSAP 등급별 망분리 도달성 리허설 | IaC validate + runbook |
| **B 데이터/스토리지** | B-1 RDS→NHN DB 4h 무손실 이전 리허설(무결성 SQL) / B-2 S3→Object Storage sync 차이 검증 / B-3 LLM 마스킹 게이트 입출력 | 리허설 + 무결성 쿼리 + dry-run diff |

각 깊이 도메인당 ≥1 시나리오 충족 (A 2개, B 3개).

---

## 1. 도메인 A — 네트워크 / 보안

### A-1. 네트워크 IaC `validate` + 보안그룹 흐름 정적 검증

**목적**: NHN/오픈스택 네트워크 Terraform 모듈이 (1) 구문·타입 유효하고 (2) **보안그룹이 `ALB→App→DB`만 허용**(DB가 인터넷·App 외 출처에서 직접 접근 불가)임을 배포 전에 보장.
**언제 실행**: 1단계(준비) — 인프라 코드 변경 시마다 CI에서. 실 apply 전 게이트.
**4h 다운타임 제약과의 연결**: 컷오버 단계가 아니라 **사전(T-7~T-0)** 검증 → 컷오버 시간 소비 0. 네트워크 결함을 컷오버 밖에서 차단.

**입력**
- `infra/nhn/`, `infra/openstack/` Terraform 모듈(§6 선택 산출물 — skeleton)
- 클라우드 계정 불필요 (`-backend=false`, `plan -refresh=false`)

**명령 / 절차**
```bash
# (1) 오프라인 검증 — 자격증명 불필요
terraform -chdir=infra/nhn fmt -recursive -check
terraform -chdir=infra/nhn init -backend=false
terraform -chdir=infra/nhn validate

# (2) 계획 산출 — provider 인증 필요(계정 보유 시에만)
terraform -chdir=infra/nhn plan -refresh=false -input=false -out=nhn.plan
terraform -chdir=infra/nhn show -json nhn.plan > nhn.plan.json

# (3) 보안그룹 흐름 정적 검증 — DB는 App SG에서만 5432 인바운드 허용
#     (모듈 중첩 대응: 재귀 탐색으로 규칙 객체를 모두 수집)
jq -r '.. | objects
  | select(.type? == "openstack_networking_secgroup_rule_v2") | .values
  | "\(.direction) \(.port_range_min)-\(.port_range_max) remote=\(.remote_group_id // .remote_ip_prefix)"
' nhn.plan.json | grep 5432
```

**기대 출력 (구체값)**
- (1) `Success! The configuration is valid.` + `fmt -check` 종료코드 `0`(출력 없음). **이 두 개가 본 과제의 오프라인 검증 증거**(계정 없음).
- (2) `Plan: 8 to add, 0 to change, 0 to destroy.` (network 모듈 리소스 수)
- (3) 5432 규칙이 정확히 1줄만:
  ```
  ingress 5432-5432 remote=<app-sg-id>
  ```
  → **`remote=0.0.0.0/0`인 5432 규칙이 0줄**이어야 PASS. (App=ALB SG에서 8080, ALB=인터넷 443만.) (2)(3)은 계정 보유 시 실행.

**실패 시 판단 기준**
- `validate` 실패(구문/타입 오류) → 머지 차단, 코드 수정 후 재실행.
- (3)에서 `from=0.0.0.0/0` 또는 ALB가 아닌 출처의 5432 ingress가 1줄이라도 출력 → **DB 노출 결함 → 머지 차단**(컷오버 진입 금지).
- `terraform init` 자체 실패(provider 다운로드 등) → provider 버전·레지스트리 확인. NHN provider 미지원 리소스면 §3 한계로 기록 + 콘솔 수동 보완 표시.

---

### A-2. CSAP 등급별 망분리 도달성 리허설

**목적**: 목표 CSAP 등급에 맞는 망분리가 **실제 네트워크 도달성**으로 성립하는지 확인. 중등급(논리)=Private subnet 격리, 상등급(물리·폐쇄망)=외부 인터넷 egress 차단.
**언제 실행**: 2단계(NHN 환경 구축) 직후, 스테이징에서.
**4h 연결**: 사전 검증 → 컷오버 외부.

**입력**
- 환경: NHN(중등급) 또는 오픈스택(상등급) 스테이징
- 점검 호스트: App subnet의 점프 호스트(또는 임시 디버그 Pod)

**명령 / 절차**
```bash
# (중등급/NHN) Private DB에 인터넷 직접 도달 불가 확인
#  - 공인망 점검 호스트에서 DB 사설 IP로 접속 시도 → 차단되어야 함
timeout 5 bash -c "cat < /dev/null > /dev/tcp/<db-private-ip>/5432"; echo "exit=$?"

#  - App subnet 점프호스트에서는 접속 가능해야 함
timeout 5 bash -c "cat < /dev/null > /dev/tcp/<db-private-ip>/5432"; echo "exit=$?"

# (상등급/오픈스택 폐쇄망) App에서 외부 인터넷 egress 차단 확인
timeout 5 curl -s -o /dev/null -w "%{http_code}" https://api.anthropic.com; echo " <- 외부"
timeout 5 curl -s -o /dev/null -w "%{http_code}" http://<내부-llm-게이트웨이>/healthz; echo " <- 내부"
```

**기대 출력 (구체값)**
- 중등급: 공인망 점검 호스트 → `exit=124`(timeout, 차단) **또는** `exit=1`(connection refused). App 점프호스트 → `exit=0`(연결).
- 상등급(폐쇄망): 외부 `api.anthropic.com` → `000`(연결 실패/차단). 내부 LLM 게이트웨이 → `200`.

**실패 시 판단 기준**
- 중등급에서 공인망 호스트가 `exit=0`(DB 직통) → **망분리 결함, 인증 부적합 → 차단**.
- 상등급에서 외부 호출이 `200` 반환(폐쇄망인데 인터넷 도달) → **데이터 주권 위반 경로 존재 → 차단** + egress 정책 재점검.
- 내부 게이트웨이가 `200`이 아니면 → 온프레미스 LLM 경로 미구성, B-3 선행 필요.

---

## 2. 도메인 B — 데이터 / 스토리지

### B-1. RDS PostgreSQL → NHN DB 4시간 무손실 이전 리허설 ★핵심

**목적**: `pg_dump|pg_restore` 이전이 **4h 안에 끝나고**, 원본=대상 **데이터 무결성(행 수 + 내용 해시)**이 100% 일치함을 리허설로 입증.
**언제 실행**: 3단계 컷오버 본 실행 전 **드라이런 1회**(운영 데이터 복제본으로) + 컷오버 본 실행 중 T+2:50 무결성 게이트.
**4시간 다운타임 제약과의 연결**: [`MIGRATION_PLAN.md` §4.2](./MIGRATION_PLAN.md) 합산표(가정 DB ≤50GB → 누적 ≤4:00). 본 리허설이 그 합산의 **실측 근거**를 만든다.

**입력**
- 원본 AWS RDS 엔드포인트, 대상 NHN RDS 엔드포인트, 동일 스키마/계정
- 환경변수: `PGPASSWORD`(Secrets Manager/Secure Key Manager에서 주입, 평문 금지)
- 유지보수 모드(원본 쓰기 중단) — 드라이런은 복제본 사용

**명령 / 절차**
```bash
# (1) 시간 측정과 함께 병렬 덤프 → 전송 → 병렬 복원
time pg_dump -h <aws-rds-host> -U app -d officeagent -Fc -j4 -f officeagent.dump
time pg_restore -h <nhn-db-host> -U app -d officeagent -j4 --no-owner officeagent.dump

# (2) 무결성: 테이블별 행 수
psql -h <aws-rds-host> -U app -d officeagent -At -F',' -c "
  SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY relname
" > aws_rowcount.csv
psql -h <nhn-db-host>  -U app -d officeagent -At -F',' -c "
  SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY relname
" > nhn_rowcount.csv
diff aws_rowcount.csv nhn_rowcount.csv

# (3) 무결성: 핵심 테이블 내용 해시 (정렬 후 단일 MD5)
SQL="SELECT md5(string_agg(t::text, ',' ORDER BY id)) FROM documents t"
psql -h <aws-rds-host> -U app -d officeagent -At -c "$SQL" > aws_hash.txt
psql -h <nhn-db-host>  -U app -d officeagent -At -c "$SQL" > nhn_hash.txt
diff aws_hash.txt nhn_hash.txt
```

**기대 출력 (구체값)**
- (1) `pg_dump` + `pg_restore` `real` 합 **≤ 160분**(§4.2의 덤프60+복원100 예산). 예: `real 58m12s` / `real 96m40s`.
- (2) `diff aws_rowcount.csv nhn_rowcount.csv` → **0줄**(모든 테이블 행 수 동일). 예: 양쪽 `documents,124530`.
- (3) `diff aws_hash.txt nhn_hash.txt` → **0줄**(해시 동일). 예: 양쪽 `9f3a...` 32자 hex 일치.

**실패 시 판단 기준 / 롤백 트리거**
- (1) 합산 시간이 **4h 예산 초과 추세**(예: 50GB에서 덤프만 120분) → 컷오버 중단, **2차안(엔진 레벨 logical replication 사전 동기)으로 전환** 후 재리허설.
- (2)/(3) diff > 0줄(행 수 또는 해시 불일치) → **무결성 실패 = 컷오버 롤백 트리거**(§4.2 T+2:50). DNS를 AWS로 원복, NHN 데이터 폐기 후 원인 분석.
- 명령 자체 실패(`connection refused`, `pg_restore` 권한 오류) → 자격·SG·`--no-owner` 확인. NHN이 `wal_level=logical`/수퍼유저를 막아 2차안 불가면 §3 한계로 기록.

---

### B-2. S3 → NHN Object Storage sync 차이 검증

**목적**: S3 호환 API로 객체를 NHN Object Storage에 옮긴 뒤 **누락·차이 0**임을 객체 수·총 바이트·재sync dry-run으로 확인.
**언제 실행**: 1단계(사전 증분 sync) + 컷오버 직전 T+0:00(최종 증분).
**4h 연결**: 대부분 사전 증분으로 끝내 컷오버 시 잔여 최소(§4.2 10분 내).

**입력**
- AWS 자격(원본), NHN Object Storage S3 호환 자격 + 엔드포인트 `https://kr1-api-object-storage.nhncloudservice.com`
- 대상 버킷/컨테이너명 동일

**명령 / 절차**
```bash
# (1) 최종 증분 sync (NHN 엔드포인트로)
aws s3 sync s3://officeagent-uploads/ s3://officeagent-uploads/ \
  --endpoint-url https://kr1-api-object-storage.nhncloudservice.com

# (2) 잔여 차이 dry-run — 0줄이어야 함
aws s3 sync s3://officeagent-uploads/ s3://officeagent-uploads/ \
  --endpoint-url https://kr1-api-object-storage.nhncloudservice.com --dryrun

# (3) 객체 수·총 바이트 비교
aws s3 ls s3://officeagent-uploads/ --recursive --summarize | tail -2 > aws_obj.txt
aws s3 ls s3://officeagent-uploads/ --recursive --summarize \
  --endpoint-url https://kr1-api-object-storage.nhncloudservice.com | tail -2 > nhn_obj.txt
diff aws_obj.txt nhn_obj.txt
```

**기대 출력 (구체값)**
- (2) dry-run 출력 **0줄**(복사할 잔여 없음).
- (3) `diff` **0줄** — 양쪽 `Total Objects: 12840` / `Total Size: 48213998123` 동일.

**실패 시 판단 기준**
- (2) dry-run이 `(dryrun) upload: ...` 줄을 출력 → 누락 객체 존재. 재sync 후 재검증. 컷오버 직전이면 잔여량 평가 후 4h 예산 내면 진행, 아니면 일정 연기.
- (3) 객체 수/바이트 불일치 → presigned URL·메타데이터 차이 의심 → 오픈스택 단계라면 `swiftstack/s3compat` op 매트릭스 대조(§3).

---

### B-3. LLM 마스킹 게이트 입출력 검증 (데이터 주권)

**목적**: OfficeAgent의 국외 LLM 호출 경로에서 **PII가 마스킹된 뒤** 외부로 나가는지(§B-4) 입출력 샘플로 확인. 개보법 §28의8 국외이전 위반 방지.
**언제 실행**: 4단계(컷오버 전환) smoke test + 정기 회귀.
**4h 연결**: 컷오버 전환 단계 게이트 — 마스킹 미동작 시 NHN 전환 보류.

**입력**
- 마스킹 게이트 엔드포인트(공통 레이어의 `llm.complete` 어댑터)
- 테스트 페이로드(가짜 PII): 이름·휴대폰·주민번호 포함

**명령 / 절차**
```bash
# 게이트로 PII 포함 프롬프트 전송, "외부로 나가는" 정규화 페이로드를 로그/리턴에서 확인
curl -s http://<masking-gateway>/v1/complete \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"민원인 홍길동 010-1234-5678 주민번호 900101-1234567 의 문서를 요약"}' \
  | jq '.outbound_payload'   # 게이트가 외부 LLM에 실제 보낸 본문
```

**기대 출력 (구체값)**
- `outbound_payload`에서 PII가 전부 치환:
  ```
  "민원인 [NAME] [PHONE] 주민번호 [RRN] 의 문서를 요약"
  ```
  → `홍길동`/`010-1234-5678`/`900101-1234567` 원문이 **0건** 포함(`grep` 카운트 0).
- 감사로그에 호출 1건 기록(요청 ID·마스킹 항목 수=3).

**실패 시 판단 기준**
- `outbound_payload`에 원문 PII가 1건이라도 남음(`grep -c '010-1234-5678'` ≥ 1) → **마스킹 누락 = 데이터 주권 위반 = 컷오버 차단**. 상등급은 애초에 외부 호출 금지(온프레미스 모델)이므로 이 게이트 자체가 없어야 정상.
- 감사로그 미기록 → 추적성 결함, 감사 요건(개보법 §29) 미충족.

---

## 3. 가정 · 한계 · 후속 검증 계획

| 가정/미확인 | 영향 | 리스크 | 후속 검증 계획 |
|------------|------|--------|---------------|
| **DB 용량 ≤50GB 가정** (실측 전) | B-1 4h 충족 | 초과 시 다운타임 위반 | 운영 DB 실제 용량 측정 → §4.2 합산 재계산 → 초과 시 2차안 |
| **NHN `wal_level=logical`·수퍼유저 허용 여부** | B-1 2차안 가능성 | 무중단 대안 불가 | NHN 기술지원 문의 |
| **NHN provider 리소스 커버리지** | A-1 validate 범위 | 일부 리소스 미지원 | Terraform Registry 문서 + validate 시도, 미지원은 콘솔 보완 |
| **Swift s3api op별 호환(presign/ACL)** | B-2 오픈스택 단계 | 앱 S3 호출 일부 실패 | `swiftstack/s3compat` op 대조 |
| **WebFetch 차단으로 1차 자료 원문 미정독** | 인용·기대출력 정확도 | Q&A 1차자료 축 | 캡처 단계 law.go.kr·docs.nhncloud.com·docs.openstack.org 직접 열람 |

---

## 4. 재현성 · 자동화 가능성

- **자동화 가능(CI 게이트)**: A-1(`terraform validate`+SG jq 검증), B-2(`s3 sync --dryrun` diff), B-3(마스킹 회귀 테스트).
- **수동·반자동(리허설)**: B-1(컷오버 리허설 — 시간 측정·무결성은 스크립트화 가능하나 컷오버 자체는 운영 이벤트), A-2(도달성 리허설 — 스테이징 점검).
- **정기 재활용**: B-1 무결성 SQL은 분기별 DR 훈련에, A-1 SG 검증은 PR마다 재사용.

---

## 5. 참고 자료

- 1차 자료·신뢰도 표기: [`MIGRATION_PLAN.md` §8](./MIGRATION_PLAN.md) (NHN docs: RDS for PostgreSQL backup-and-restore, Object Storage S3 호환 API; OpenStack swift s3_compat; law.go.kr 개보법 §28의8·§29).
- 4h 합산 근거: [`MIGRATION_PLAN.md` §4.2](./MIGRATION_PLAN.md).

---

_v1 (2026-06-17, 학습용). 실 apply 없는 리허설 명세 — 기대 출력은 구체값으로. `<...>` placeholder는 실행 시 실제 호스트/ID로 치환._
