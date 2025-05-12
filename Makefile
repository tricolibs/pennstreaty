default: docker-status

.PHONY: docker-status
docker-status:
	docker ps

.PHONY: reindex-solr
reindex-solr:
	docker exec pt-web python /app/manage.py rebuild_index
