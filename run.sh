#!/bin/sh

export COMPOSE_FILE_PATH="${PWD}/target/classes/docker/docker-compose.yml"

if [ -z "${M2_HOME}" ]; then
  export MVN_EXEC="mvn"
else
  export MVN_EXEC="${M2_HOME}/bin/mvn"
fi

start() {
    docker volume create alfresco-demo-data-acs-volume
    docker volume create alfresco-demo-data-db-volume
    docker volume create alfresco-demo-data-ass-volume
    docker-compose -f "$COMPOSE_FILE_PATH" up --build -d
}

start_share() {
    docker-compose -f "$COMPOSE_FILE_PATH" up --build -d alfresco-demo-data-share
}

start_acs() {
    docker-compose -f "$COMPOSE_FILE_PATH" up --build -d alfresco-demo-data-acs
}

down() {
    if [ -f "$COMPOSE_FILE_PATH" ]; then
        docker-compose -f "$COMPOSE_FILE_PATH" down
    fi
}

purge() {
    docker volume rm -f alfresco-demo-data-acs-volume
    docker volume rm -f alfresco-demo-data-db-volume
    docker volume rm -f alfresco-demo-data-ass-volume
}

build() {
    $MVN_EXEC clean package
}

build_share() {
    docker-compose -f "$COMPOSE_FILE_PATH" kill alfresco-demo-data-share
    yes | docker-compose -f "$COMPOSE_FILE_PATH" rm -f alfresco-demo-data-share
    $MVN_EXEC clean package -pl alfresco-demo-data-share-amp,alfresco-demo-data-share-docker
}

build_acs() {
    docker-compose -f "$COMPOSE_FILE_PATH" kill alfresco-demo-data-acs
    yes | docker-compose -f "$COMPOSE_FILE_PATH" rm -f alfresco-demo-data-acs
    $MVN_EXEC clean package -pl alfresco-demo-data-repo-amp,alfresco-demo-data-repo-docker
}

tail() {
    docker-compose -f "$COMPOSE_FILE_PATH" logs -f
}

tail_all() {
    docker-compose -f "$COMPOSE_FILE_PATH" logs --tail="all"
}

prepare_test() {
    $MVN_EXEC verify -DskipTests=true -pl alfresco-demo-data-repo-amp,alfresco-demo-data-repo-amp-docker
}

test() {
    $MVN_EXEC verify -pl alfresco-demo-data-repo-amp
}

case "$1" in
  build_start)
    down
    build
    start
    tail
    ;;
  build_start_it_supported)
    down
    build
    prepare_test
    start
    tail
    ;;
  start)
    start
    tail
    ;;
  stop)
    down
    ;;
  purge)
    down
    purge
    ;;
  tail)
    tail
    ;;
  reload_share)
    build_share
    start_share
    tail
    ;;
  reload_acs)
    build_acs
    start_acs
    tail
    ;;
  build_test)
    down
    build
    prepare_test
    start
    test
    tail_all
    down
    ;;
  test)
    test
    ;;
  *)
    echo "Usage: $0 {build_start|build_start_it_supported|start|stop|purge|tail|reload_share|reload_acs|build_test|test}"
esac