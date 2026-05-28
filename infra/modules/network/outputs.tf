/**
 * Network 추상 모듈 — provider-neutral 출력 시그니처
 *
 * 본 모듈은 outputs 시그니처 정의만 — 실제 값은 provider별 root에서 채움.
 * 다른 모듈(database / compute)이 가져다 쓰는 인터페이스.
 *
 * 사용 예 (root에서):
 *   output "vpc_id" {
 *     value = aws_vpc.this.id              # AWS root
 *     # 또는 nhncloud_networking_network_v2.this.id   # NHN root
 *   }
 */

# 본 파일은 인터페이스 명세이며 실제 output 값은 root module에서 정의함.
# 다른 모듈이 본 모듈의 outputs.tf 시그니처를 보고 어떤 키를 기대해야 하는지 안다.

# 시그니처 (root module에서 모두 채워야 함):
# - vpc_id                   : string  (VPC / Virtual Network ID)
# - public_subnet_ids        : list(string)
# - private_app_subnet_ids   : list(string)
# - private_db_subnet_ids    : list(string)
# - external_subnet_ids      : list(string)   # LLM egress 격리 zone
# - management_subnet_ids    : list(string)
# - security_group_ids       : map(string)    # key = zone명, value = SG ID
