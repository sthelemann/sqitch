##############################
FROM sqitch/sqitch@sha256:0492ae14ce7ddfa01a9e79c7c0c466de902bca2f24c20a16acb198b87ae2bcca AS development

WORKDIR /srv/app

COPY ./docker-entrypoint.sh /usr/local/bin/

VOLUME /srv/app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["sqitch", "deploy", "&&", "sleep", "infinity"]


###########################
FROM postgres:15.3@sha256:475a0d447384a5353a366db110bbf8b982b825aff53cdcf39e88dc2b97d1c7e1 AS build

ENV POSTGRES_DB=maevsi
ENV POSTGRES_PASSWORD=postgres

WORKDIR /srv/app

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
      libdbd-pg-perl postgresql-client sqitch

COPY ./src ./

RUN export SQITCH_TARGET="$(cat SQITCH_TARGET.env)" \
  && docker-entrypoint.sh postgres & \
  while ! pg_isready -h localhost -U postgres -p 5432; do sleep 1; done \
  && sqitch deploy -t db:pg://postgres:postgres@/maevsi \
  && pg_dump -s -h localhost -U postgres -p 5432 maevsi | sed -e '/^-- Dumped/d' > schema.sql

##############################
FROM alpine:3.18.0@sha256:02bb6f428431fbc2809c5d1b41eab5a68350194fb508869a33cb1af4444c9b11 AS validate

WORKDIR /srv/app

COPY ./schema ./
COPY --from=build /srv/app ./

RUN diff schema.sql schema.definition.sql


##############################
FROM sqitch/sqitch@sha256:0492ae14ce7ddfa01a9e79c7c0c466de902bca2f24c20a16acb198b87ae2bcca AS production

WORKDIR /srv/app

COPY ./docker-entrypoint.sh /usr/local/bin/
COPY --from=validate /srv/app ./

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["sqitch", "deploy", "&&", "sleep", "infinity"]
