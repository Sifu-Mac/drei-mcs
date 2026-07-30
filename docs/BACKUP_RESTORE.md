# PostgreSQL backup and restore

This runbook verifies a DREI Asset Review PostgreSQL backup without touching the
production database, containers, network, or volumes.

## Safety boundary

- Never restore into the `drei-review` Compose project.
- Never reuse `drei-review-postgres` or any other production volume.
- Never load `.env.production` for a restore test.
- Keep database dumps outside Git and do not print their contents.
- Do not modify or version the VPS-local `backup-postgres.sh`.
- Restore Active Storage separately only when a complete recovery is required.
  The database dump alone does not contain files from `drei-review-storage`.

`bin/verify_postgres_backup` enforces an isolated Compose project name beginning
with `drei-restore-`. Its PostgreSQL service uses a project-scoped temporary
volume and fixed, non-production credentials. An exit trap removes the container,
network, and volume on success, failure, or interruption.

## Prerequisites

- Docker with the Compose plugin
- read access to an existing `*.sql.gz` backup
- enough temporary disk space for the uncompressed database
- the `postgres:16-alpine` image (or permission to pull it)

Check the production stack before the test without displaying its environment:

```bash
docker compose --env-file .env.production ps
```

## Isolated verification

From the repository, pass the dump as an absolute path:

```bash
bin/verify_postgres_backup /absolute/path/to/drei-review_TIMESTAMP.sql.gz
```

The verifier:

1. checks gzip integrity;
2. creates a uniquely named `drei-restore-*` Compose project;
3. starts PostgreSQL 16 with a new project-scoped volume;
4. restores with `psql` and `ON_ERROR_STOP=1`;
5. reports only aggregate checks: public table count, migration count, presence
   of required tables, and row counts for campaigns, boards, columns, and tasks;
6. removes the isolated container, network, and volume.

It intentionally suppresses SQL output during import. Do not add queries that
print user records, credentials, tokens, comments, filenames, or other content.

## Verification criteria

A backup passes when:

- gzip validation succeeds;
- the SQL import exits successfully without ignored errors;
- all eight required structural tables are present;
- `schema_migrations` can be queried;
- aggregate queries for campaigns, boards, board columns, and tasks succeed;
- no `drei-restore-*` container, network, or volume remains afterward;
- the production `db` and `web` services remain in their previous state.

The aggregate row counts are diagnostics, not a guarantee of application-level
correctness. A full disaster-recovery exercise must additionally pair the
database dump with a matching Active Storage backup and validate the application
in a non-production environment.

## Failure and manual cleanup

The script cleans up automatically. If the host or Docker daemon stops before the
trap runs, list only restore-scoped resources:

```bash
docker ps -a --filter name=drei-restore-
docker volume ls --filter name=drei-restore-
docker network ls --filter name=drei-restore-
```

Identify the exact project name from those results, then remove only that project:

```bash
docker compose --project-name drei-restore-EXACT_ID \
  --file docker-compose.restore.yml down --volumes --remove-orphans
```

Never substitute `drei-review` for the project name in cleanup commands.

## Recovery procedure

An actual recovery is a separate, explicitly approved operation:

1. stop writes and record the incident timeline;
2. preserve the failed database and storage volumes before changing anything;
3. verify the chosen database dump with this isolated procedure;
4. verify availability of the matching Active Storage backup;
5. create a new recovery environment and restore both assets there;
6. validate migrations, authentication, boards, tasks, and representative
   attachments without exposing their contents;
7. obtain approval before switching traffic or replacing any production volume;
8. retain the pre-recovery volumes until the recovery is accepted.

Automated encrypted offsite backups and a matching Active Storage backup remain
separate operational requirements.
