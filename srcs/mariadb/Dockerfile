FROM mariadb:10.6

HEALTHCHECK --interval=5s --timeout=3s \
  CMD mysqladmin ping -u root -p${MARIADB_ROOT_PASSWORD} || exit 1
  