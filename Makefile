default: docker-status

# The dump-database task needs not to echo the command into the sql that
# is output!
.SILENT: dump-database

.PHONY: docker-status
docker-status:
	docker ps

.PHONY: reindex-solr
reindex-solr:
	docker exec pt-web python /app/manage.py rebuild_index --noinput

.PHONY: create-superuser
create-superuser:
	docker exec -it pt-web python /app/manage.py createsuperuser

.PHONY: fix-solr-permissions
fix-solr-permissions:
	echo "This must be run as root."
	chown -R solr:solr data/solr

.PHONY: dump-database
dump-database:
	source .env ; docker compose exec db bash -c "pg_dump --create --clean --user=$$POSTGRES_USER $$POSTGRES_DB"

.PHONY: import-database
import-database:
	docker compose cp "$$DB_DUMP" db:/tmp/pt-db.sql
	#note that since we need to drop the current DB if it exists, we connect to a different one
	source .env ; docker compose exec db bash -c "psql --user=$$POSTGRES_USER template1 < /tmp/pt-db.sql"
	docker compose exec db rm /tmp/pt-db.sql
