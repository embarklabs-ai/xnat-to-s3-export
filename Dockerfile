# Debian 11 is end of life and its CA bundle still trusts the compromised eMudhra roots.
FROM python:3.13-slim-trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y curl unzip

# AWS CLI 2.38.4+ ships a clean CA bundle; the installer matches the build platform.
ARG AWSCLI_VERSION=2.38.4
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m)-${AWSCLI_VERSION}.zip" -o awscliv2.zip \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf aws awscliv2.zip \
  && rm -rf \
        aws \
        /usr/local/aws-cli/v2/current/dist/aws_completer \
        /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/current/dist/awscli/examples \
  && apt-get remove curl -y \
  && apt-get remove unzip -y \
  && apt-get auto-clean -y


#Path to a directory to store scripts
COPY run.py /usr/local/bin/
WORKDIR /usr/local/bin

LABEL org.nrg.commands="[{\"name\": \"xnat2s3\", \"label\": \"xnat2s3\", \"description\": \"Export Session Data as zipped DICOM scans from XNAT to an S3 bucket\", \"version\": \"1.0.1\", \"schema-version\": \"1.0\", \"image\": \"radiologicsremya/xnat2s3-zip:1.0.1\", \"type\": \"docker\", \"command-line\": \"python /usr/local/bin/run.py #BUCKETNAME# -p \$PROJECT_ID -t \$SUBJECT_LABEL -m \$SESSION_LABEL\", \"override-entrypoint\": true, \"mounts\": [{\"name\": \"in\", \"writable\": false, \"path\": \"/input\"}], \"environment-variables\": {\"SESSION_LABEL\": \"#SESSION_LABEL#\", \"SUBJECT_LABEL\": \"#SUBJECT_LABEL#\", \"PROJECT_ID\": \"#PROJECT_ID#\"}, \"ports\": {}, \"inputs\": [{\"name\": \"S3-bucket\", \"description\": \"AWS S3 Bucket\", \"type\": \"string\", \"default-value\": \"s3://bucket-name\", \"required\": true, \"replacement-key\": \"#BUCKETNAME#\", \"command-line-flag\": \"-b\", \"select-values\": []}, {\"name\": \"project-id\", \"description\": \"XNAT Project ID\", \"type\": \"string\", \"required\": true, \"replacement-key\": \"#PROJECT_ID#\", \"select-values\": []}, {\"name\": \"subject-label\", \"description\": \"XNAT Subject Label\", \"type\": \"string\", \"required\": true, \"replacement-key\": \"#SUBJECT_LABEL#\", \"select-values\": []}, {\"name\": \"session-label\", \"description\": \"XNAT Session LABEL\", \"type\": \"string\", \"required\": true, \"replacement-key\": \"#SESSION_LABEL#\", \"select-values\": []}], \"xnat\": [{\"name\": \"xnat2s3\", \"label\": \"xnat2s3\", \"description\": \"Export Session Data from XNAT to an S3 bucket\", \"contexts\": [\"xnat:imageSessionData\"], \"external-inputs\": [{\"name\": \"session\", \"description\": \"Input session\", \"type\": \"Session\", \"required\": true, \"provides-files-for-command-mount\": \"in\", \"load-children\": false}], \"derived-inputs\": [{\"name\": \"subject\", \"type\": \"Subject\", \"required\": true, \"user-settable\": false, \"load-children\": true, \"derived-from-wrapper-input\": \"session\", \"multiple\": false}, {\"name\": \"subject-label\", \"type\": \"string\", \"required\": true, \"provides-value-for-command-input\": \"subject-label\", \"load-children\": true, \"derived-from-wrapper-input\": \"subject\", \"derived-from-xnat-object-property\": \"label\", \"multiple\": false}, {\"name\": \"project\", \"type\": \"Project\", \"required\": true, \"user-settable\": false, \"load-children\": true, \"derived-from-wrapper-input\": \"session\", \"multiple\": false}, {\"name\": \"project-id\", \"type\": \"string\", \"required\": true, \"provides-value-for-command-input\": \"project-id\", \"load-children\": true, \"derived-from-wrapper-input\": \"project\", \"derived-from-xnat-object-property\": \"id\", \"multiple\": false}, {\"name\": \"session-label\", \"type\": \"string\", \"required\": true, \"provides-value-for-command-input\": \"session-label\", \"load-children\": true, \"derived-from-wrapper-input\": \"session\", \"derived-from-xnat-object-property\": \"label\", \"multiple\": false}]}], \"reserve-memory\": 1750, \"limit-memory\": 1750, \"network\": \"host\", \"container-labels\": {}, \"generic-resources\": {}, \"ulimits\": {}}]"

