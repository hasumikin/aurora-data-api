## Example app

### Stack

- Serverless Framework
  - Lamdda functions (outside VPC)
  - RDS Aurora Serverless v1 (inside VPC) + 

### Getting started

```sh
docker compose build
docker compose run --rm serverless rake db:create_database
docker compose run --rm serverless bundle exec aurora-data-api export
docker compose run --rm serverless rake db:migrate_dry_run
docker compose run --rm serverless rake db:migrate
```
```sh
docker compose run --rm serverless rake db:migrate_dry_run
=> -- Nothing is modified --
```
```sh
docker compose up
```
```sh
curl http://localhost:4000/offline/hello
```

```sh
curl -X POST http://localhost:4000/offline/create_user \
-H 'Content-Type: application/json' \
-d '{"name":"HASUMI Hitoshi", "internet_account":"hasumikin"}'

curl -X POST http://localhost:4000/offline/create_entry \
-H 'Content-Type: application/json' \
-d '{"title":"My first atrticle", "user_id":1}'

curl -X POST http://localhost:4000/offline/delete_entry \
-H 'Content-Type: application/json' \
-d '{"entry_id":1}'
```
