# xnat2s3 v1.0

XNAT Container Service command that exports an imaging session from XNAT to an S3 bucket. Each scan's DICOMs are zipped (no compression) and uploaded as a single `.zip` object.

## Repo Structure

```
export-discovery-to-S3bucket/
├── command.json                 # XNAT Container Service command definition
├── Dockerfile                   # Python slim + AWS CLI v2
└── run.py                       # Core logic (zip per scan, upload, clear temp cache)
```

## How It Works

1. Reads scans from the read-only `/input` mount XNAT provides for the session.
2. For each scan, zips its `DICOM/` folder into `<scan_number>.zip` in a container-local temp directory.
3. Uploads the zip to S3, then deletes the local copy before moving on to the next scan, so peak disk usage stays at one scan.
4. Skips XNAT catalog files (`scan_*_catalog.xml`); only imaging data is uploaded.
5. Uses `ZIP_STORED` — no recompression of DICOM bytes; files inside each zip are byte-identical to the originals.

## Inputs

| Name | Type | Source in XNAT | Description |
|------|------|----------------|-------------|
| `S3-bucket` | string | User-entered at runtime | S3 bucket URI (e.g. `s3://my-bucket`) |
| `project-id` | string | Auto-derived from session | XNAT Project ID |
| `subject-label` | string | Auto-derived from session | XNAT Subject label |
| `session-label` | string | Auto-derived from session | XNAT Session label |

## S3 Layout

```
s3://<bucket>/<project_id>/<subject_label>/<session_label>/<scan_number>.zip
```

One object per scan.

## Prerequisites

- An S3 bucket the container can write to.
- AWS credentials available to the container (env vars, instance profile, or mounted `~/.aws/credentials`). The script uses the AWS CLI's standard credential chain.
- XNAT with the Container Service plugin installed.

## Running

From a session page in XNAT, open **Run Containers → xnat2s3**, enter the S3 bucket URI, and submit. The other inputs are filled in automatically. Can also be batch launched from a Project page in XNAT using XNAT's processing dashboard.
