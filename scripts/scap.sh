#!/bin/bash

# Download and install all needed dependencies to conduct a scan
sudo apt install -y openscap-scanner openscap-utils unzip
wget https://github.com/ComplianceAsCode/content/releases/download/v0.1.81/scap-security-guide-0.1.81.zip

# unzip the downloaded profiles
unzip scap-security-guide-0.1.81.zip

# run an oscap scan
sudo oscap xccdf eval \
    --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
    --results /tmp/ubuntu-cis-results.xml \
    --report /tmp/ubuntu-cis-report.html \
    /home/admin/scap-security-guide-0.1.81/ssg-ubuntu2404-ds.xml

# generate a remediation script
oscap xccdf generate fix \
    --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
    --fix-type bash \
    /home/admin/scap-security-guide-0.1.81/ssg-ubuntu2404-ds.xml \
    > cis-remediation.sh