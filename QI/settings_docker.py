import os
import dj_database_url

from .settings import *

DEBUG = os.environ.get('DEBUG', '').lower() in ['true', '1']

ALLOWED_HOSTS = ['*']

SECRET_KEY = os.environ.get('SECRET_KEY')

DATABASES['default'] = dj_database_url.config(
    default=os.environ.get('DB_URL')
)

HAYSTACK_CONNECTIONS = {
    'default': {
        'ENGINE': 'haystack.backends.solr_backend.SolrEngine',
        'URL': os.environ.get('SOLR_URL'),
    },
}
