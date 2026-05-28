---
marp: true
theme: default
paginate: true
size: 16:9
---

# OfficeAgent
## AWS → NHN Cloud 마이그레이션 설계

NextIntelligence DevOps/AIOps 채용 과제
발표자: pear-c (bsh00611@gmail.com)
발표일: 2026-06 (마감 후 7일 이내)
저장소: `pear-c/officeagent-devops-onboarding-challenge`

---

## 표준 시작 — 가장 큰 미해결 위험

> "본인이 깊이 다룬 2개 도메인 중, 가장 큰 미해결 위험과 그 근거를 먼저 말씀해 주세요."

### **B-3: LLM API 외부 호출 데이터 주권**

**위험**: Anthropic·OpenAI 호출이 개인정보보호법 §28의8 ④ "보호위원회가 보호 수준을 갖춘 것으로 인정한 국가/국제기구" 적용 가능 여부 미확인. 미적용이면 §28의8 ① 정보주체 동의 필수 + §28의9 보호위원회 중지 명령 대응 필요.

**근거**:
- 법령 §28의8/§28의9/§39의13/§75 조문 골조 직접 확인 (law.go.kr)
- 보호위원회 *"보호 수준 인정 국가"* 공시 직접 미접근 — 운영 단계 법무 자문 필수
- 마스킹 라이브러리(잠정 결론 1단계)로도 잔여 위험 100% 제거 불가

→ **본 발표는 이 위험을 어떻게 다루는가에 집중**.

---

## 과제 본질 + 평가 비중

**메타 목표**: *"바이브 코딩(AI 페어 프로그래밍)으로 낯선 영역(NHN·CSAP·오픈스택)의 멀티 환경 배포 설계를 실제로 해낼 수 있는가"*

| 평가 영역 | 비중 |
|----------|-----:|
| 마이그레이션 설계·의사결정 | **30%** |
| 멀티 환경 추상화 | **20%** |
| 검증 가능성 (§1.3 입력·명령·기대·실패판단) | **20%** |
| 조사·학습 깊이 (1차 자료·학습 후 설계 변경) | **20%** |
| 발표·소통 | 10% |
| **Track C** (학습 궤적, 별도 20점) | 60~75점 경계 결정 카드 |

---

## 시스템 컨텍스트 + 핵심 제약

**가상 AWS 스펙** (PRD §부록):
- VPC + ALB + ECS Fargate × 2 + RDS PG Multi-AZ + S3 + ElastiCache + IAM
- 동시 < 200 / RPS 5(평균)·50(피크) / 일평균 업로드 500건

**박제 제약**:
- **다운타임 ≤ 4시간** (주말 야간 1회) + **데이터 무손실**
- **CSAP 컴플라이언스**: NHN 단계부터
- **외부 의존**: Anthropic + OpenAI API (= 국외 호출, **데이터 주권 핵심 난제**)

**핵심 결정** (사용자 합의 2026-05-26):
- 깊이 도메인 2개: **A 네트워크/보안 + B 데이터/스토리지**
- 목표 CSAP 등급: **중등급** (논리적 망분리, 일반 공공 시나리오)
- 마이그레이션 모델: AWS 유지 + NHN 추가 (오픈스택은 장기 로드맵)

---

## 깊이 도메인 선정 이유 + 본론 흐름

| 도메인 | 선정 이유 | 의사결정 박스 |
|--------|----------|--------------|
| **A 네트워크/보안** | CSAP 핵심 관문 = 망분리. 평가 강조 영역 *멀티 환경 추상화 20%* 와 정확히 일치 | A-1·A-2·A-3 |
| **B 데이터/스토리지** | 4h 다운타임 + 데이터 주권 = 본 과제 가장 무거운 영역. LLM API 외부 호출이 본질 난제 | B-1·B-2·B-3 |

**얕은 매핑** (3 도메인 — MIGRATION_PLAN §2.4):
- C 컴퓨트: ECS Fargate → NKS (CSAP 적용 범위 미확인)
- D 운영·관측: CloudWatch → NHN Log & Crash + Monitoring
- E 비용·규제: CSAP 인증 수수료 5천만~1억원 + ISMS-P 별개

→ 욕심 내 3개 얕게 다루는 대신 2개 깊이 — **잠정 결론 박제 + 6요소 충족**.

---

## A-1 — VPC ↔ NHN VPC 매핑

### 잠정 결론
AWS VPC `10.0.0.0/16` → **NHN VPC `10.0.0.0/16`** (동일 CIDR) + SG positive/stateful 평면 전환.

### 근거 (1차 자료)
- NHN VPC docs (en/console-guide): *"All VPCs must be located in the three address ranges shown below, where a private network can be configured... you must specify a network area that is larger than 24bit-256"*  → RFC 1918 + 최소 /24
- NHN Security Groups overview: *"규칙으로 지정한 트래픽은 허용하고, 나머지 트래픽은 차단"* + stateful → AWS SG와 의미 거의 동등

### 트레이드오프
| 축 | 동일 CIDR | 다른 CIDR |
|----|----------|----------|
| 운영성 | ↑ (같은 IP 디버깅 표) | ↓ |
| Peering 충돌 | ↑ 위험 | ↓ |
| 추상화 | Kustomize overlay 단순 | 분기 코드 |

### 리스크
NHN VPC의 **DVR(Distributed Virtual Routing)** 기본 동작이 p99 latency에 미치는 영향 미확인 + NAT Gateway 매니지드 여부 미명시.

---

## A-2 — CSAP 중등급 5 zone 망분리

### 잠정 결론
**5 zone** = 관리망(10.0.100.0/24) + Public(10.0.10.0/24) + App(10.0.20.0/24) + DB(10.0.30.0/24) + **외부 통신**(10.0.40.0/24)

### 핵심 룰
- App·DB zone outbound = **차단** (LLM 호출 불가)
- 외부 통신 zone에서만 Anthropic/OpenAI 호출 (마스킹 라이브러리 경유)
- Public zone (ALB) inbound 443 only / DB zone inbound = App zone SG만

### 근거
- **클라우드법 §23** + NHN Cloud (공공기관용) **IaaS CSAP** 2022.12.13~2027.12.12 (인증 페이지 캡처)
- NHN SG stateful + 다중 SG 적용 가능 → zone별 SG 설계 자연스러움

### CSAP 통제 매핑 (VALIDATION §1.1.2)
충족 7건 / **부분 4건** (RDS 암호화 / 로그 보존 기간 / 국외 이전 통제 / DR 훈련 주기) / 미충족 0건

### 리스크
NHN **매니지드 서비스**(NKS·OBS·KMS)의 CSAP 적용 범위 미명시 — Day 5 gov-nhncloud.com 보강 후보

---

## A-3 — IAM ↔ NHN 권한 ★ 핵심 발견

### 잠정 결론 — **AWS Trust Policy/AssumeRole → NHN 직접 등가 없음**

1. 운영자 = NHN IAM 사용자 + MEMBER 역할 + **MFA 강제** (이메일/휴대폰)
2. 워크로드 = **Pod ServiceAccount + Secret manifest** + Secure Key Manager 사이드카 또는 init container
3. 시크릿 회전 = Secure Key Manager 자동 30일+ + 핫 리로드 또는 rolling restart

### 근거 (1차 자료 직접 확인)
- NHN IAM QuickStart: 역할 = NONE/MEMBER/BILLING_VIEWER/BUDGET_ADMIN **4종**. *"IAM 계정의 기본 역할은 NONE으로 설정"*. **Instance Profile/Service Role/AssumeRole 명시 0건**.
- NHN Secure Key Manager: 클라이언트 인증 = **IPv4/MAC/인증서** → AWS IAM Role 기반 KMS와 패러다임 다름

### NHN-only 종속 시그널
| 영역 | AWS | NHN |
|------|-----|-----|
| 시크릿 주입 | Task Role 자동 | Secret manifest 명시 + Secure Key Manager 사이드카 |
| 워크로드 ID | IRSA (IAM Role for SA) | 환경변수 / Vault Agent injector (대안) |

---

## B-1 — RDS → NHN DB 4h 무중단 이전

### 잠정 결론
**사전 incremental sync (S3→NHN OBS) + `pg_basebackup` 동일 버전 + Object Storage 경유 import**

### 근거 (Day 1 NHN docs 4건 직접 확인)
- *"외부 PostgreSQL의 마스터로부터 강제로 복제하도록 설정하면 고가용성 및 일부 기능들이 정상적으로 동작하지 않습니다"* → **logical replication 미지원**
- Parameter Group의 wal_level / max_wal_senders / max_replication_slots **언급 0건**
- Backup and Restore: *"pg_basebackup과 동일한 버전을 사용해야 합니다"* + OBS 경유 import 가능

### 4h 합산 시뮬레이션 (VALIDATION B-2 `sim-4h-budget.sh`)
| 입력 | 합산 | 결과 |
|------|----:|:----:|
| 50GB / 100MBps | 172분 | ✅ PASS |
| 100GB / 100MBps | 319분 | ❌ FAIL (79분 초과) |
| 100GB / 200MBps | 187분 | ✅ PASS |

### Fallback (4h 초과 시)
데이터 정리 / 대역폭 확보 / 윈도우 분할 / AWS DMS 호환 재확인

---

## B-2 — S3 → NHN Object Storage sync

### 잠정 결론
**`aws s3 sync` 그대로 사용** + `--endpoint-url https://kr1-api-object-storage.nhncloudservice.com` + AWS CLI **≤ 2.22.35** 박제

### 근거 (NHN OBS S3 API guide 직접 인용)
- *"NHN Cloud Object Storage provides API compatible with S3 API of AWS object storage"*
- *"AWS CLI versions up to 2.22.35 are supported in NHN Cloud Object Storage"*
- 멀티파트 최소 5MiB 지원

### 운영 박제
```bash
aws s3 sync s3://officeagent-documents-prod \
    s3://officeagent-documents-prod \
    --endpoint-url https://kr1-api-object-storage.nhncloudservice.com \
    --dryrun  # 컷오버 전 차이 확인 (VALIDATION §2.3 B-3)
```

### 리스크
- `aws s3 sync --delete` 호환 미명시
- Pre-signed URL 명시 없음
- AWS CLI 2.23+ 자동 업그레이드 시 깨질 위험 → `pip install awscli==2.22.35` + CI lock

---

## B-3 — LLM API 데이터 주권 ★ 가장 큰 미해결 (1/2)

### 잠정 결론 — **3단 방어 전략**

1. **호출 전 마스킹·비식별화** (필수, 1단계)
2. **감사 로그 100%** (필수, 2단계 — §28의9 중지 명령 대응)
3. **국산 모델(HyperCLOVA X) 옵션 비교** (장기 검증, 3단계)

### 근거 — 법령 §28의8 ① ~ ④
| 요건 | 의미 |
|------|------|
| ① 정보주체 동의 | 매 호출 실효성 의문 |
| ② 법령·조약 | 해당 없음 |
| ③ 보호위원회 인증 | 절차 가능 |
| ④ 보호 수준 인정 국가 | **미국 포함 여부 미확인 ★** |

§28의9: 보호위원회의 국외 이전 **중지 명령** 가능
§39의13 + §75: 과징금·과태료

---

## B-3 — LLM API 데이터 주권 (2/2)

### 5개 대안 비교 (트레이드오프)
| 대안 | 비용 | 응답 품질 | 잔여 위험 |
|------|:---:|:--------:|:--------:|
| 호출 차단 (LLM 미사용) | 0 | ❌ 핵심 가치 상실 | 0 |
| 동의만 + 마스킹 없음 | 0 | 100% | ★★★★ |
| 마스킹 + 감사 (잠정 1·2단계) | ★ | 90~95% | ★★ |
| 국산 모델 매니지드 (3단계) | ★★ | 미검증 | ★ |
| 온프레미스 오픈 모델 | ★★★★ | 80~95% | 0 (장기) |

### 가장 큰 미해결 위험 (스스로 명시)
- **미국이 §28의8 ④ "보호 수준 인정 국가" 포함 여부 미확인** — 보호위원회 공시 직접 확인 + 법무 자문 필요
- 마스킹 라이브러리 정확도 ≥ 95% 잔여 위험
- 응답 unmask 시 응답 자체에 PII 포함 가능성

### 검증 시나리오
VALIDATION B-4 마스킹 단위 테스트 (재현율 ≥ 95%) + B-5 HyperCLOVA X 응답 품질 비교 (Day 4·5 PoC 후보)

---

## 검증 산출물 (VALIDATION.md 시나리오 7개)

| ID | 시나리오 | 4종 + 롤백 |
|----|---------|----------|
| A-1 | 망분리 zone 다이어그램 + CSAP 통제 매핑 11건 | ✅ |
| A-2 | NHN VPC + 5 zone Subnet + 5 SG `terraform validate` PASS | ✅ |
| B-1 | RDS↔NHN DB row count + MD5 hash 무결성 SQL | ✅ |
| B-2 | 4h 다운타임 `sim-4h-budget.sh` (10/50/100GB × 100/200MBps) | ✅ |
| B-3 | `aws s3 sync --dryrun` + 멀티파트 5MiB 경계 테스트 | ✅ |
| B-4 | 마스킹 함수 단위 테스트 (재현율 ≥ 95% + 잔여 PII 0) | ✅ |
| B-5 | HyperCLOVA X vs Anthropic 응답 품질 (Day 4·5 PoC 선택) | ⚪ |

**모두 4종 명시**: 입력 / 명령 / 기대 출력 / 실패 판단 기준 + 롤백 트리거 + 복귀 경로 — §6 트리거 #2 방어선.

---

## 추상화 — 4영역 분리 + NHN-only 종속

### ARCHITECTURE.md §2.1 4영역 분리도 (요약)
공통 (provider-neutral) | AWS-only | NHN-only | 오픈스택-only (장기)

### NHN-only 종속 식별 (★ 1~5 정량화)
| 영역 | NHN-only 의존 | 오픈스택 단계 자체 구축 | 비용 |
|------|--------------|----------------------|----:|
| 매니지드 DB | NHN RDS | PostgreSQL + Patroni + etcd | ★★★★ |
| Object Storage | NHN OBS | Swift | ★★★ |
| KMS | Secure Key Manager | Barbican + HSM | ★★★★ |
| K8s | NKS | Magnum + kubespray | ★★★★ |
| LB | NHN LB | Octavia / HAProxy | ★★★ |
| 모니터링 | Log & Crash + Monitoring | Prometheus + Grafana + Loki | ★★ |

### 코드 입증 (`infra/`)
`infra/nhn/` ↔ `infra/aws/` 비교: same shape, different provider. `infra/openstack/README.md`는 의식적 비어 있음.

---

## Q&A 1축 — 의사결정 근거 표 (부록)

| 의사결정 | 잠정 결론 | 1차 자료 인용 |
|---------|----------|--------------|
| A-1 VPC | 동일 CIDR `10.0.0.0/16` | NHN VPC console-guide RFC 1918 + ≥ /24 |
| A-2 망분리 | 5 zone | 클라우드법 §23 + NHN IaaS CSAP 보유 |
| A-3 IAM | Trust Policy 등가 없음 → Secret manifest | NHN IAM QuickStart 4종 역할 명시 |
| B-1 4h | pg_basebackup + OBS | Day 1 NHN RDS 4건 직접 인용 |
| B-2 S3 sync | aws s3 sync --endpoint-url | NHN OBS S3 API guide ≤ 2.22.35 |
| B-3 LLM | 3단 방어 (마스킹·감사·국산) | 개보법 §28의8/§28의9 |

12건 1차 자료: Day 1 NHN RDS 4건 + Day 3 NHN docs 7건 + 개보법 §28의8 골조

---

## Q&A 2축 — 채택 안 한 대안의 단점 + 설계 깨질 시나리오 (부록)

| 박스 | 채택 안 한 대안 | 단점 |
|------|---------------|------|
| A-1 | 다른 CIDR 사용 | 운영자 mental map 부담 |
| A-2 | 물리적 망분리(상등급) | 퍼블릭 클라우드 부적합 |
| A-3 | 외부 Vault | 추가 인프라 운영 부담 |
| B-1 | AWS DMS | NHN 호환 미명시 |
| B-1 | pg_dump+restore | 5~8h, 4h 초과 |
| B-2 | NHN 전용 CLI | 운영자 두 도구 mental map |
| B-3 | 호출 차단 | OfficeAgent 핵심 가치 상실 |

**본 설계가 깨질 시나리오**:
1. **데이터 ≥ 100GB** → B-1 4h 초과 → 윈도우 분할 fallback
2. **미국이 §28의8 ④ 미포함 결정** → B-3 마스킹만으로 부족, 동의 강제 필요
3. **NKS의 CSAP 적용 범위가 IaaS만** → C 도메인 회피 설계 추가 필요

---

## Q&A 3축 — 1차 자료 12건 (부록)

### Day 1 NHN RDS docs (4건)
- DB Engine: PG 14·17 지원, replication 키워드 0건
- DB Instance: *"외부 PostgreSQL 마스터 복제 시 정상 동작 안 함"*
- Parameter Group: wal_level/max_wal_senders/max_replication_slots 0건
- Backup and Restore: pg_basebackup 동일 버전 요건 + OBS 경유

### Day 3 추가 (8건)
- NHN Security Groups overview (positive + stateful)
- NHN Object Storage S3 API guide (AWS CLI ≤ 2.22.35)
- NHN 리전 가이드 (판교·평촌·광주·도쿄)
- NHN VPC Console Guide (RFC 1918 + /24~/28 + DVR)
- NHN IAM QuickStart (4종 역할, Trust Policy 등가 없음)
- NHN Secure Key Manager (IPv4/MAC/인증서 인증)
- NHN CSAP 인증 페이지 (IaaS 공공기관용 2022.12~2027.12)
- 개인정보 보호법 §28의8/§28의9/§39의13/§75 (조문 골조)

법령 본문 직접 인용은 미접근 — **솔직히 명시** (조문 번호·요건 골조만 박제)

---

## Q&A 4축 — NHN-only 종속 식별 (부록)

### 오픈스택 단계에서 재작성 불가피한 영역

| NHN 매니지드 | 자체 구축 도구 | 운영 영역 변화 |
|------------|-------------|--------------|
| NHN RDS for PG | PostgreSQL + Patroni + etcd | HA failover 직접 운영 |
| NHN OBS | Swift | 다중 노드 + replica 직접 |
| Secure Key Manager | Barbican + HSM 옵션 | 키 회전·감사 직접 |
| NHN IAM | Keystone (LDAP/AD 연동) | 사용자·그룹·정책 매핑 |
| NKS | Magnum + kubespray | cluster lifecycle 직접 |
| NHN LB | Octavia / HAProxy keepalived | HA failover 직접 |
| Log & Crash | Prometheus + Grafana + Loki | 룰·지표 정의 재구성 |

### 코드로 입증
- `infra/nhn/network.tf` ↔ `infra/aws/network.tf` 시그니처 동일 (추상화 가능)
- `infra/openstack/README.md` 비어 있음 = 의식적 미작성, 장기 로드맵

---

## Q&A 5축 — 학습 궤적 (부록)

### 막힌 지점 3건 + 돌파

**1. NHN docs URL 패턴 redirect**
- 시도: `/ko/Network/VPC/ko/overview/` → 302 redirect
- 돌파: WebSearch로 실제 URL 발견 (`/en/Network/VPC/en/console-guide/` + `/zh/Storage/Object Storage/zh/s3-api-guide/`). 1차 자료 부재 시 §6 트리거 #4 위반 가능 → 재시도 패턴이 핵심

**2. 법령 본문 직접 fetch 어려움**
- 시도: law.go.kr `lsInfoP.do?lsId=011357` → navigation만, 본문 미접근
- 돌파: WebSearch로 §28의8 ① ~ ④ 요건 골조 박제 + *"본문 미접근"* 솔직히 명시 → §6 트리거 #4 회피

**3. 단순 1:1 매핑 회귀 방지**
- 시도: 처음 §2.2 작성 시 AWS SG ↔ NHN SG 단순 매핑
- 돌파: 6요소 박스 패턴 (잠정·근거·대안·트레이드오프·리스크·검증)을 강제 → 의사결정 박스 6개 × 평균 3개 대안 = 총 20개 대안 명시

### 학습 후 설계 변경
- A-3 핵심 발견 → ARCHITECTURE.md §2.2 시크릿 주입 행 추가
- VALIDATION을 MIGRATION_PLAN §6에서 별도 파일 분리
- 5 zone 망분리 정착 (4 zone 후보 → 외부 통신 zone 별도 추가)

---

## 후속 과제 (운영 단계 검증 항목)

### 1차 자료 보강 (Day 5)
- KISA 인증 운영 가이드 → CSAP 통제 매핑 11건 중 부분 4건 확정
- 공공기관용 NHN docs (gov-nhncloud.com SSL 우회) → NKS/OBS/KMS CSAP 적용 범위
- 보호위원회 *"보호 수준 인정 국가"* 공시 직접 확인 (B-3 R1)

### 검증 자동화
- `sim-4h-budget.sh` (작성됨) → 분기별 DR 훈련 재활용
- `terraform validate` (사용자 환경 CLI 설치 후) → CI 단계 박제
- 마스킹 단위 테스트 (Phase 2+) → PR 머지 전 차단 게이트

### 본 설계가 깨질 가장 큰 시나리오
**미국이 §28의8 ④ 미포함 + 데이터 ≥ 100GB + NKS의 CSAP 미적용** = 3중 위험. 발생 시 LLM 호출 차단 + 윈도우 분할 + IaaS 직접 사용 회피 설계 동시 발동.

---

## Thank you

### 본 발표 요약 3 lines
1. 깊이 도메인 A·B 각 3 의사결정 박스 = 6요소 (잠정·근거·대안·트레이드오프·리스크·검증) 충족
2. 1차 자료 12건 직접 인용 + 본문 미접근은 솔직히 명시 — Track C 시그널
3. 가장 큰 미해결 위험 1~2개를 발표 5분 안에 스스로 명시 — PRD §발표 가산 영역

### 산출물
- `MIGRATION_PLAN.md` 47KB · `ARCHITECTURE.md` 12KB · `VALIDATION.md` 32KB
- `infra/` Terraform skeleton (NHN + AWS + OpenStack)
- `retros/` 학습 일지 (Day 1~3, Track C 자료)
- `deck/slides.md` (이 문서)

### Q&A 30분 — 5축
의사결정 근거 · 대안 단점 · 1차 자료 출처 · NHN-only 종속 · 학습 궤적
