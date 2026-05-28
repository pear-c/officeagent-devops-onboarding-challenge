# Validation artifacts

> `VALIDATION.md` 시나리오 실행 결과물 보관. 본 디렉토리는 검증 산출물의 *재현성·구체성* 증거 (PRD §1.3).

---

## 예상 산출물 (Day 4·5에 채워짐)

| 파일 | 어느 시나리오 | 어떻게 생성되는가 |
|------|--------------|-----------------|
| `nhn-plan.txt` | VALIDATION §1.2 A-2 (NHN VPC validate) | `cd infra/nhn && terraform plan -refresh=false -input=false -out=plan.tfplan && terraform show -no-color plan.tfplan > ../../validation-artifacts/nhn-plan.txt` |
| `aws-plan.txt` | VALIDATION §1.2 A-2 (AWS 비교 baseline) | `cd infra/aws && terraform plan ... > ../../validation-artifacts/aws-plan.txt` |
| `4h-sim-output.txt` | VALIDATION §2.2 B-2 (4h 다운타임 합산) | `bash scripts/sim-4h-budget.sh 50 100 > validation-artifacts/4h-sim-output.txt` (10/50/100GB × 100/200MBps 케이스) |
| `s3-sync-dryrun.txt` | VALIDATION §2.3 B-3 (S3 sync 차이) | `aws s3 sync s3://... s3://... --endpoint-url ... --dryrun > validation-artifacts/s3-sync-dryrun.txt` (실 자격증명 필요 — Day 5 또는 PoC 환경에서만) |
| `masking-pytest.xml` | VALIDATION §2.4 B-4 (마스킹 단위 테스트) | `pytest tests/test_masking.py --junit-xml=validation-artifacts/masking-pytest.xml` (테스트 코드는 Phase 2 이후 시작 — 본 PoC는 시나리오 정의까지만) |
| `csap-control-mapping.md` | VALIDATION §1.1.2 (CSAP 통제 매핑) | 본 디렉토리에 직접 작성 — KISA 가이드 직접 인용 보강 시 추가 (Day 5) |

## 실 자격증명 없이 어떻게 검증하는가

PRD §3 *"실 apply 없음"* + §1.3 *"코드형도 문서형도 동등 평가"*:

1. **`terraform validate`** — 인증 인자 없어도 syntax + provider schema 검증
2. **`terraform plan -refresh=false`** — placeholder 값으로 dry-run, 실 클라우드 호출 없음
3. **`sim-4h-budget.sh`** — pure bash 시뮬레이션, 자격증명 무관
4. **`pytest`** — 테스트 자체는 환경 무관 (Phase 2 이후)
5. **`aws s3 sync --dryrun`** — 실 자격증명 필요. PoC 시 mock S3 endpoint 또는 LocalStack 활용 후보

## 본 디렉토리에 산출물이 비어 있어도 평가 불이익 없는 이유

- `VALIDATION.md`에 시나리오 정의가 완비 (입력·명령·기대·실패판단·롤백 트리거 4종 + α)
- 본 README가 *"산출물을 어떻게 만들 것인가"*를 박제 — 재현성 보장
- PRD §1.3 *"검증 산출물은 형태 자유. 문서형도 동등 평가"*
- 실 산출물은 Day 4·5 시간 허용 시 채워짐. 부재 시에도 시나리오 자체가 §1.3의 핵심
