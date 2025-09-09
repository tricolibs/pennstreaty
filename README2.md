These are additional observations from turning the production system into a
docker project and making related changes. Much of the original README might
apply, but I didn't really get into the weeds of figuring out all of how the
project works, just enough to transform it.

I'll try to cover what one needs to know to develop and deploy and so on.

# Developing

## Environment file

You need to copy or link the `.env.dev` file over to `.env`, as docker compose
will use it for environment variables. For development you shouldn't need to
make any changes.

## Docker

You'll need to have docker and docker compose installed to develop. Copy or link
`compose-dev.yaml` to `compose.yaml`.

The two most important commands are `docker compose up -d` and
`docker compose down`, which bring the stack up and down respectively. Also
relevant is `docker compose build`, which builds the custom container that runs
the pennstreaty django app.

You can see the containers used in the `compose.yaml` file. They are

* web - this is the container that runs the django app proper. The
  `Dockerfile` specifies how it is built. Basically it starts from a base
  container with python installed, sets an environment variable to say where the
  Django settings are, installs dependencies, copies this directory into the
  container to `/app` which is the application directory, and then starts up the
  application. For development, when the container is started up via docker
  compose, docker compose will mount this directory _live_ to `/app`, so Django
  will pick up changes directly and you don't need to keep rebuilding to get
  them. On production that doesn't happen, a rebuild is needed to pick up the
  changes. The application is exposed directly on port 8000  (i.e. at
  `http://localhost:8000`)
* db - this runs the postgres database. The data is stored under the `data/db`
  directory.
* solr - runs the solr index. Its data is stored under `data/solr`. Solr is
  exposed on port 8983 if needed.
* proxy - this isn't strictly necessary for development, but is here to mirror
  the production system better. As a result, you can also access the application
  at `https://localhost`. I don't recall - for this you may need to install the
  `mkcert` program and use it to create a certificate for `localhost` and
  install that in your local cert chain. If so this is simple - see
  https://github.com/FiloSottile/mkcert.

## Makefile

A `Makefile` is provided to automate common tasks. For example, to recreate the
Solr index you can do `make reindex-solr`.

I recommend adding tasks as they come up. The reindex-solr task is an 
example of how you can run `manage.py` tasks inside the container - any
of those that might be needed are obvious candidates. Note that it's best
to use an editor that knows how to edit Makefiles - in particular, Makefiles 
are a little odd in that leading spaces need to be tabs, so best to leave 
that kind of formatting to the editor.

## Database

You'll want to install a copy of the database to develop. There are make 
tasks to help. 

You can dump a copy of the database (e.g. from the production server) with
`make dump-database > pt-db.sql`. You can then copy that to the development
environment. 

When importing there can't be any other connections to the database. So  
you'll need to run only the db container: 
`docker compose down`
`docker compose up db -d`

Then run the import make task - you need to do this with the location to
the dumped database, for example if it is in `tmp/pt-db.sql`:

`DB_DUMP=tmp/pt-db.sql make import-database`

You can then bring up the rest of the stack with `docker compose up -d`.

## Media

You'll want to grab the stuff under the `media/` directory from the production
server if you want to see everything properly.

## Creating a superuser/admin interface

You can create a superuser for Django with `make create-superuser`, just
follow the prompts.

Once you have this, you can log in at `localhost/admin` to access the (very
unpolished) admin interface.

# Production

We note here only significant differences from development.

## Environment file

You need to copy or link the `.env.prod` file over to `.env` and fill in the
`SECRET_KEY`, `POSTGRES_PASSWORD`, and
`HOST`. 

## Docker

In production the version of the app baked into the container is used. 

The proxy will automatically get certs for the host defined in the environment
and the redirecting hosts. See `caddy-conf/prod/Caddyfile` for details on 
how things are set up.

## superuser/admin

I don't know if there are any existing superusers on the production side,
but you should be able to create and use them in the same way.