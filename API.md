# Sara Alert API

Sara Alert provides a RESTful API to interact with the system to perform various actions. Actions include reading, writing, and updating monitoree data as well as reading monitoree lab results and monitoree daily reports. The data accepted and returned by the API corresponds to FHIR R4; the FHIR Patient resource is used for monitorees, the Observation FHIR resource is used for monitoree lab results, and the FHIR QuestionaireResponse FHIR resource is used for monitoree daily reports.

- [CapabilityStatement](#cap)
  - [GET [base]/fhir/r4/CapabilityStatement](#cap-get)
- [Authenticating](#auth)
  - [POST [base]/oauth/token](#auth-post)
- [Reading](#read)
  - [GET [base]/Patient/[:id]](#read-get-pat)
  - [GET [base]/Observation/[:id]](#read-get-obs)
  - [GET [base]/QuestionaireResponse/[:id]](#read-get-que)
  - [GET [base]/Patient/[:id]/$everything](#read-get-all)
- [Creating](#create)
  - [POST [base]/Patient](#create-post-pat)
- [Updating](#update)
  - [PUT [base]/Patient/[:id]](#update-put-pat)
- [Searching](#search)
  - [GET /fhir/r4/Patient?parameter(s)](#search-get)

<a name="cap"/>

## CapabilityStatement

A capability statement is available at `[base]/fhir/r4/CapabilityStatement`:

<a name="cap-get"/>

### GET `[base]/fhir/r4/CapabilityStatement`

```json
{
  "status": "active",
  "kind": "instance",
  "software": {
    "name": "Sara Alert",
    "version": "v1.4.1"
  },
  "implementation": {
    "description": "Sara Alert API"
  },
  "fhirVersion": "4.0.1",
  "format": [
    "xml",
    "json"
  ],
  "rest": [
    {
      "mode": "server",
      "security": {
        "cors": true,
        "service": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/restful-security-service",
                "code": "OAuth"
              }
            ]
          }
        ]
      },
      "resource": [
        {
          "type": "Patient",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "update"
            },
            {
              "code": "create"
            },
            {
              "code": "search-type"
            }
          ],
          "searchParam": [
            {
              "name": "family",
              "type": "string"
            },
            {
              "name": "given",
              "type": "string"
            },
            {
              "name": "telecom",
              "type": "string"
            },
            {
              "name": "email",
              "type": "string"
            }
          ]
        },
        {
          "type": "Observation",
          "interaction": [
            {
              "code": "read"
            }
          ]
        },
        {
          "type": "QuestionnaireResponse",
          "interaction": [
            {
              "code": "read"
            }
          ]
        }
      ]
    }
  ],
  "resourceType": "CapabilityStatement"
}
```

<a name="auth"/>

## Authenticating

Authenticate using your Sara Alert account credentials via `/oauth/token`:

<a name="auth-post"/>

### POST `[base]/oauth/token`

#### Request Body

```json
{
  "grant_type" : "password",
  "username" : "state1_epi@example.com",
  "password" : "1234567ab!"
}
```

#### Response

```json
{
  "access_token": ">>>> token <<<<",
  "token_type": "Bearer",
  "expires_in": 7199,
  "created_at": 1589332127
}
```

Use this token for all subsequent requests, via Authorization header, i.e. `'Authorization': "Bearer >>>> token <<<<"`.

<a name="read"/>

## Reading

The API supports reading monitorees, monitoree lab results, and monitoree daily reports.

<a name="read-get-pat"/>

### GET `[base]/Patient/[:id]`

Get a monitoree via an id, e.g.:

```json
{
  "id": 1,
  "meta": {
    "lastUpdated": "2020-05-11T01:06:42+00:00"
  },
  "language": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      }
    }
  ],
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "1002-5",
            "display": "American Indian or Alaska Native"
          }
        },
        {
          "url": "text",
          "valueString": "American Indian or Alaska Native"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "F"
    }
  ],
  "name": [
    {
      "family": "Labadie45",
      "given": [
        "Victor87",
        "McCullough03"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "4732004860fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1977-04-09",
  "address": [
    {
      "line": [
        "553 Shanahan View"
      ],
      "city": "Lake Reynaldaburgh",
      "state": "New Mexico",
      "postalCode": "24801-6534"
    }
  ],
  "resourceType": "Patient"
}
```

<a name="read-get-obs"/>

### GET `[base]/Observation/[:id]`

Get a monitoree lab result via an id, e.g.:

```json
{
  "id": 1,
  "meta": {
    "lastUpdated": "2020-05-11T02:01:16+00:00"
  },
  "status": "final",
  "subject": {
    "reference": "Patient/1"
  },
  "effectiveDateTime": "2020-05-11T00:00:00+00:00",
  "valueString": "positive",
  "resourceType": "Observation"
}
```

<a name="read-get-que"/>

### GET `[base]/QuestionnaireResponse/[:id]`

Get a monitoree daily report via an id, e.g.:

```json
{
  "id": 3,
  "meta": {
    "lastUpdated": "2020-05-11T01:06:37+00:00"
  },
  "status": "completed",
  "subject": {
    "reference": "Patient/1"
  },
  "item": [
    {
      "text": "cough",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "text": "difficulty-breathing",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "text": "fever",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "text": "used-a-fever-reducer",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "text": "chills",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "text": "repeated-shaking-with-chills",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "text": "muscle-pain",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "text": "headache",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "text": "sore-throat",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "text": "new-loss-of-taste-or-smell",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    }
  ],
  "resourceType": "QuestionnaireResponse"
}
```

<a name="read-get-all"/>

### GET `[base]/Patient/[:id]/$everything`

Use this route to retrieve a FHIR Bundle containing the monitoree, all their lab results, and all their daily reports.

```json
{
  "id": "9e02e507-b1c0-4fda-ac40-73dab0bd7dc9",
  "meta": {
    "lastUpdated": "2020-05-11T22:12:22-04:00"
  },
  "type": "searchset",
  "total": 8,
  "entry": [
  ],
  "resourceType": "Bundle"
}
```

<a name="create"/>

## Creating

The API supports creating new monitorees.

<a name="create-post-pat"/>

### POST `[base]/Patient`

#### Request Body

```json
{
  "resourceType": "Patient",
  ...
}
```

#### Response

On success, the server will return the newly created resource with an id. This is can be used to retrieve or update the record moving forward.

```json
{
  "resourceType": "Patient",
  "id": 1,
  ...
}
```

<a name="update"/>

## Updating

The API supports updating existing monitorees.

<a name="update-put-pat"/>

### PUT `[base]/Patient/[:id]`

#### Request Body

```json
{
  "resourceType": "Patient",
  ...
}
```

#### Response

On success, the server will update the existing resource given the id.

```json
{
  "resourceType": "Patient",
  "id": 1,
  ...
}
```

<a name="search"/>

## Searching

The API supports searching for monitorees.

<a name="search-get"/>

### GET `/fhir/r4/Patient?parameter(s)`

The exact parameters allowed are: `given`, `family`, `telecom`, and `email`.

GET `/fhir/r4/Patient?given=testy&family=mctest`

```json
{
  "id": "e0c97e69-8234-4b10-abe5-d57071ef3409",
  "meta": {
    "lastUpdated": "2020-05-12T22:19:30-04:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/15",
      "resource": {
        "id": 15,
        "meta": {
          "lastUpdated": "2020-05-11T02:18:23+00:00"
        },
        "name": [
          {
            "family": "McTest",
            "given": [
              "Testy"
            ]
          }
        ],
        ...
        "resourceType": "Patient"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
