/**
 * NHN Object Storage — placeholder
 *
 * 본 파일도 database.tf와 동일 — resource 명을 직접 박지 않고 모양·이유만 주석 박제.
 *
 * 관련 의사결정:
 *   - MIGRATION_PLAN.md §B-2 (S3→NHN OBS sync = aws s3 sync + endpoint URL + AWS CLI ≤ 2.22.35)
 *   - VALIDATION.md §2.3 B-3 (aws s3 sync --dryrun 차이 검증)
 *
 * 예상 모양 (Day 5 확정):
 *
 *   # 옵션 A: OpenStack Swift 기반 (NHN provider 기본 패턴)
 *   resource "nhncloud_objectstorage_container_v1" "documents" {
 *     name   = "${var.service_name}-${var.environment}-documents"
 *     region = var.region
 *     metadata = {
 *       "X-Container-Meta-Csap-Tier" = "medium"
 *     }
 *   }
 *
 *   resource "nhncloud_objectstorage_container_v1" "assets" {
 *     name   = "${var.service_name}-${var.environment}-assets"
 *     region = var.region
 *   }
 *
 *   # 옵션 B: 별도 매니지드 자원이 있다면 (provider docs Day 5 직접 확인)
 *
 * 추가 검증 항목 (VALIDATION B-3 시나리오와 연결):
 *   - S3 호환 API endpoint = https://kr1-api-object-storage.nhncloudservice.com (region별)
 *   - 멀티파트 최소 5MiB 지원 명시 (NHN docs)
 *   - AWS CLI ≤ 2.22.35 + `--endpoint-url` 옵션
 *
 * 한계 (database.tf와 동일 사유):
 *   - Provider v1.0.9의 Object Storage resource 명 직접 검증 미달성 (Day 5)
 *   - 본 PoC는 한계의 솔직한 명시 — PRD §1.3 활용
 */
