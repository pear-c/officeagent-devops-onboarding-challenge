/**
 * NHN RDS for PostgreSQL — placeholder
 *
 * 본 파일은 resource 명을 직접 박지 않고 "어떤 모양이어야 하는지" 주석으로만 박제한다.
 * 이유: NHN Cloud Terraform Provider v1.0.9의 RDS resource 정확한 이름(`nhncloud_db_*`?)
 *      이 Day 4 시점에 직접 검증되지 않음 — Day 5에 registry.terraform.io 직접 확인 후
 *      코드 작성.
 *
 * 관련 의사결정:
 *   - MIGRATION_PLAN.md §B-1 (RDS→NHN DB 4h 무중단 이전 = pg_basebackup + OBS 경유)
 *   - VALIDATION.md §2.1 B-1 (row count + MD5 hash 무결성 검증)
 *
 * 예상 모양 (실제 resource 명은 Day 5 확정):
 *
 *   resource "nhncloud_db_instance_v1" "officeagent" {
 *     name           = "${var.service_name}-${var.environment}-pg"
 *     engine         = "postgresql"
 *     engine_version = "14.19"          # AWS RDS와 minor 동일 (B-1 §pg_basebackup 동일 버전)
 *     instance_class = "db.t3.medium"
 *     storage_size   = 100              # GB
 *     network_id     = nhncloud_networking_network_v2.vpc.id
 *     subnet_id      = nhncloud_networking_subnet_v2.private_db.id
 *     security_group_ids = [nhncloud_networking_secgroup_v2.private_db.id]
 *     backup_retention_period = 7
 *     ha             = true            # Multi-AZ 등가
 *   }
 *
 * 본 PoC에서 미작성 사유 (한계 명시):
 *   1. Provider v1.0.9의 RDS resource 명 직접 검증 미달성 (Day 5)
 *   2. `nhncloud_db_*` 패턴 추정만 가능 — registry 직접 확인 필요
 *   3. AWS DMS / pg_basebackup 경로는 Terraform 책임 아님 — VALIDATION B-2 시나리오 sim-4h-budget.sh
 *
 * 이 placeholder가 §6 불합격 트리거 #2(검증 부재) 위반이 아닌 이유:
 *   - MIGRATION_PLAN.md §B-1 의사결정 박스가 6요소 충족
 *   - VALIDATION.md B-1·B-2 시나리오가 정량 검증 (row count·MD5·4h 합산 시뮬레이션)
 *   - 본 파일은 한계의 솔직한 명시 — PRD §1.3 "코드형도 문서형도 동등 평가" 활용
 */
