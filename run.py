#!/usr/bin/env python3
import subprocess
import argparse
import sys
import os
import tempfile
import zipfile

def run_command(cmd, error_message):
    """Run a subprocess command and exit on failure."""
    try:
        result = subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.stdout:
            print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(error_message, file=sys.stderr)
        if e.stderr:
            print(e.stderr, file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description="This script exports Discovery Session Data to a user-specified S3 bucket."
    )
    parser.add_argument('-b', '--bucket', required=True, help="AWS S3 bucket URI (e.g., s3://your-bucket)")
    parser.add_argument('-p', '--projid', required=True, help="Project ID")
    parser.add_argument('-t', '--subid', required=True, help="Subject label")
    parser.add_argument('-m', '--sesid', required=True, help="Session label")
    
    args = parser.parse_args()

    # Ensure no trailing slash on the bucket URI.
    bucket = args.bucket.rstrip('/')
    projid = args.projid
    subid = args.subid
    sesid = args.sesid

    # Remove pre-existing session data.
    # This command removes only objects under the session label folder (i.e. <sesid>/*)
    s3_rm_target = f"{bucket}/{projid}/{subid}/"
    include_pattern = f"{sesid}/*"
    rm_cmd = [
        "aws", "s3", "rm", s3_rm_target,
        "--recursive",
        "--exclude", "*",
        "--include", include_pattern
    ]
    print("Removing pre-existing session data from S3...")
    run_command(rm_cmd, "Error: Failed to remove pre-existing session data.")

    # Zip each scan's DICOMs and upload immediately, so peak disk usage is one
    # scan's zip at a time. /input is mounted read-only from the XNAT archive,
    # so zips are built in a temp dir that's cleaned up on exit (including on
    # exception).
    sample_path = "/input"
    scans_dir = os.path.join(sample_path, "SCANS")
    if not os.path.exists(scans_dir):
        raise FileNotFoundError(f"No SCANS folder found in {sample_path}")

    with tempfile.TemporaryDirectory(prefix="xnat2s3-") as zips_dir:
        for scan_number in os.listdir(scans_dir):
            dicom_dir = os.path.join(scans_dir, scan_number, "DICOM")
            if not os.path.exists(dicom_dir):
                print(f"Warning: No DICOM folder found in {dicom_dir}, skipping")
                continue
            zip_path = os.path.join(zips_dir, f"{scan_number}.zip")
            with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_STORED) as zipf:
                for root, _, files in os.walk(dicom_dir):
                    for file in files:
                        # Skip XNAT catalog XMLs (e.g. scan_1_catalog.xml) —
                        # they describe the resource, not the imaging data.
                        if file.lower().endswith(".xml"):
                            continue
                        file_path = os.path.join(root, file)
                        relative_path = os.path.relpath(file_path, dicom_dir)
                        zipf.write(file_path, arcname=relative_path)
            print(f"Created zip: {zip_path}")

            s3_target = f"{bucket}/{projid}/{subid}/{sesid}/{scan_number}.zip"
            cp_cmd = ["aws", "s3", "cp", zip_path, s3_target]
            print(f"Uploading {scan_number}.zip to S3...")
            run_command(cp_cmd, f"Error: Failed to upload {scan_number}.zip")
            os.remove(zip_path)

    print("Session successfully exported!")

if __name__ == "__main__":
    main()
