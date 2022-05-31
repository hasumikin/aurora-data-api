## Example app

### Stack

- Ruby + aurora-data-api gem
- Serverless Framework
- Lambda functions outside VPC
- RDS Aurora Serverless v1 inside VPC + Data API (HTTP endpoint)
- Secrets Manager, IAM, etc.

### Try in your local computer with docker

```sh
docker compose build
```

#### Create database

```sh
docker compose run --rm serverless rake db:create
```

#### Confirm the SQL of migration

```sh
docker compose run --rm serverless rake db:migrate_dry_run
```

#### Migrate

```sh
docker compose run --rm serverless rake db:migrate
```

#### Start containers

```sh
docker compose up
```

### APIs

```sh
curl http://localhost:4000/offline/hello
```

#### Create a user

```sh
curl -X POST http://localhost:4000/offline/create_user \
-H 'Content-Type: application/json' \
-d '{"name":"HASUMI Hitoshi", "internet_account":"hasumikin"}'
```

#### List users

```sh
curl http://localhost:4000/offline/users
```

#### Update the user

```sh
curl -X PUT http://localhost:4000/offline/update_user \
-H 'Content-Type: application/json' \
-d '{"id":1, "name":"anonymous", "internet_account":"hasumikin"}'
```

#### Create an entry

```sh
curl -X POST http://localhost:4000/offline/create_entry \
-H 'Content-Type: application/json' \
-d '{"title":"My first atrticle", "user_id":1}'
```

#### List entries

```sh
curl http://localhost:4000/offline/entries
```

#### Delete the entry

```sh
curl -X POST http://localhost:4000/offline/delete_entry \
-H 'Content-Type: application/json' \
-d '{"entry_id":1}'
```

### Deploy to AWS

Supposing you have an AWS credential in $HOME/.aws/credentials.
It has to have almost administrative permission in order to provision a Serverless Framework app:

```
[YourAWSProfileName]
aws_access_key_id=AKIAxxxxxxxxxxxxxxxxx
aws_secret_access_key=xxxxxxxxxxxxxxxxxxxxxxxxxx
```

```sh
serverless deploy --stage production --aws-profile [YourAWSProfileName]
```

About 30 minutes later, all stacks should've been provisioned in AWS.

- You can see API endpoints by `sls info --stage production --aws-profile [YourAWSProfileName]`
- Open the AWS management console
- Find *RDS_SECRET_ARN* value lools like `arn:aws:secretsmanager:ap-northeast-1:01234567890:secret:aurora-data-api-example-production-AuroraUserSecret-xxxxxx` in "Secrets Manager"

    <img src="https://raw.githubusercontent.com/hasumikin/aurora-data-api/master/example/doc/query-edidor.png" width="400" />

- Go to "RDS" > "Query Editor" of and connect with the secret ARN above, then run the content of `db/schema.sql` to create tables

Now that you can call APIs like:

```sh
curl https://xxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/production/hello
```
