Env variables:

- MAINT_GITLAB_URL (gitlab root url)
- MAINT_GITLAB_TOKEN (gitlab api key)
- USERS (csv file with header "email,group_id")

```csv
email,group_id
test@mail.com,158
test@mail.com,159
```

Usage:

```bash
./maintainer.sh
```