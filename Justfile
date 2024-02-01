dev:
    just start-db

first-setup:
    podman pull docker.io/library/mysql
    podman create --name demodb -p 3306:3306 -e MYSQL_ROOT_PASSWORD=password --health-cmd='mysqladmin ping --silent' mysql || true
    podman start demodb
    just __wait-for-db
    sqlx database setup
    
__wait-for-db:
    #!/usr/bin/env bash
    source ./scripts/wait-for-db.sh
