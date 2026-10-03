# mysql-operator

Manage your Mysql databases and users in the whole new way and deploy them along with your app!

## Why I created this operator?

I manage multiple Wordpress websites and it was always an additional work to manage Mysql databases for them.
Of course I automated management using Ansible playbooks, but nevertheless instead of deploying just Kubernetes resources from the template I had to edit inventory file, run playbook to provision databases and users and then get the password and put it in Kubernetes secret. A lot of boring work.

## How it works

This operator provides Custom Resource Definitions that allow you to manage databases and users for Mysql clusters.

First, we need to define a cluster (with secret for string password) - the cluster tells mysql-operator how to connect to Mysql host for management of databases and users:

```yaml
apiVersion: mysql.operator.luktom.net/v1
kind: MysqlCluster
metadata:
  name: example-mysqlcluster
spec:
  host: mysql.test.luktom.net
  username: administrator
  secretRef:
    name: example-mysqlcluster
    namespace: default
---
apiVersion: v1
stringData:
  password: TopSecretPasswordToDatabase
kind: Secret
metadata:
  name: example-mysqlcluster
type: Opaque
```

Keep in mind that the user specified above has to have permissions to create/drop database and to manage users.

Next, we can provision a database:

```yaml
apiVersion: mysql.operator.luktom.net/v1
kind: MysqlDatabase
metadata:
  name: example-mysqldatabase
spec:
  dropOnDelete: false
  clusterRef:
    name: example-mysqlcluster
```

The `name` of the resource maps to the name of the database.
`clusterRef` refers to the above defined MysqlCluster object with connection details.
`dropOnDelete` tells operator if it should drop the database when CRD is deleted from Kubernetes.

After creating above object in Kubernetes you should see the database provsioned.

The same principles apply to the user:

```yaml
apiVersion: mysql.operator.luktom.net/v1
kind: MysqlUser
metadata:
  name: example-mysqluser
spec:
  clusterRef:
    name: hosting
  privileges: ""
```

`name` is mapped to username to create, `clusterRef` refers to the cluster to use, and `privileges` allows to specifiy all privileges user should have after creation.
The user is always dropped when CRD is deleted from Kubernetes.

As you can see, there's no way to specify a password for the user. This is because the password is randomly generated and saved in a new Kubernetes secret called `mysql-user-example-mysqluser` (`mysql-user-` prefix + `name` from metadata).

This way, you can use a secret directly in your deployment, like that:

```yaml
...
- name: MYSQL_PASSWORD
  valueFrom:
      secretKeyRef:
        key: password
        name: "mysql-user-example-mysqluser"
...
```

Keep in mind that `MysqlUser` and `MysqlDatabase` are namespace-scoped CRD, `MysqlCluster` is cluster-scoped, so you can refer to it from any namespace.

## Installation

Kubernetes 1.16 or newer is required. Install the CRDs and wait for them to
be established before starting the operator:

```
git clone https://github.com/halkeye/mysql-operator
cd mysql-operator/deploy
kubectl apply -f crds/mysql_v1_mysqlcluster_crd.yaml \
  -f crds/mysql_v1_mysqldatabase_crd.yaml \
  -f crds/mysql_v1_mysqluser_crd.yaml
kubectl wait --for=condition=Established --timeout=60s \
  crd/mysqlclusters.mysql.operator.luktom.net \
  crd/mysqldatabases.mysql.operator.luktom.net \
  crd/mysqlusers.mysql.operator.luktom.net
kustomize build | kubectl apply -f -
```

The CRDs use `apiextensions.k8s.io/v1`; custom resources and watches continue
to use `mysql.operator.luktom.net/v1`. Spec and status fields are preserved,
including the status written by the Ansible operator. If the operator reports
`no matches for kind "MysqlDatabase"`, check that all three CRDs are installed
and established, then restart the operator.

## Docker images

GitHub Actions builds `build/Dockerfile` on pull requests without publishing.
Pushes to `master` and tags matching `v*` publish images to
`ghcr.io/halkeye/mysql-operator` using the built-in `GITHUB_TOKEN`, with no
Docker Hub credentials required. The workflow can also be run manually;
only the default branch and `v*` tags can publish.

Default-branch builds update `latest`, branch builds are tagged with the branch
name, and tag builds use the Git tag (for example, `v1.0.0`). Published builds
also receive a `sha-<short-commit>` tag. Both deployment containers use `latest`;
pin both to the same release tag or digest for reproducible deployments.

Ensure the GHCR package is public so Kubernetes can pull it without credentials,
or configure an image pull secret for a private package.
