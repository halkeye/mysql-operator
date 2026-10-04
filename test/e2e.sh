#!/usr/bin/env bash
# Applies test resources to the current kube context and verifies results.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f mysql.yaml
kubectl -n default rollout status deploy/test-mysql --timeout=180s
kubectl apply -f resources.yaml

wait_created() {
  local kind=$1 name=$2
  for _ in $(seq 60); do
    [ "$(kubectl -n default get "$kind" "$name" -o jsonpath='{.status.created}' 2>/dev/null)" = "true" ] && return 0
    sleep 5
  done
  echo "$kind/$name was not created" >&2
  kubectl -n mysql-operator logs deploy/mysql-operator --tail=100 >&2 || true
  return 1
}
wait_created mysqldatabase testdb
wait_created mysqluser testuser

mysql_q() { kubectl -n default exec deploy/test-mysql -- mysql -uroot -prootpass -N -e "$1"; }
has_line() { grep -qx "$1" <<<"$2"; }
has_line testdb "$(mysql_q 'show databases')"
has_line testuser "$(mysql_q 'select user from mysql.user')"
echo "database and user created"

kubectl -n default delete mysqluser testuser --timeout=120s
kubectl -n default delete mysqldatabase testdb --timeout=120s
! has_line testdb "$(mysql_q 'show databases')"
echo "database dropped on delete"
