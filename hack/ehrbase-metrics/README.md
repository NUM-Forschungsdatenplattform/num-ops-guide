# EHRbase Metrics

## SwaggerUI

http://localhost:8080/ehrbase/swagger-ui/index.html

To get the count of all patients (EHRs) in an openEHR system using AQL, you can use the COUNT function as follows:

```sql
SELECT
    COUNT(e/ehr_id/value) AS total_patients
FROM
    EHR e
```

```json
{
  "q": "SELECT COUNT(e/ehr_id/value) AS total_patients FROM EHR e",
  "columns": [
    {
      "path": "/COUNT(e/ehr_id/value)",
      "name": "total_patients"
    }
  ],
  "rows": [[1059]]
}
```

## curl

Request:

```bash
curl -s -u "$SECURITY_AUTHADMINUSER:$SECURITY_AUTHPASSWORD" "Accept: application/json"  'http://localhost:8080/ehrbase/rest/openehr/v1/query/aql?q=SELECT%20COUNT%28e%2Fehr_id%2Fvalue%29%20AS%20total_patients%20FROM%20EHR%20e' | jq '.rows[0][0]'
```

Response:

1059

## Container

k run -it --rm debian --image=debian

apt-get update && apt-get install -y curl jq
