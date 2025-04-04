#!/bin/bash

set -e

dnf install python3-pip -y
dnf install python3-setuptools -y

pip install -r ./nextflow-source/ph-metagenomics/requirements.txt
cd ./nextflow-source/ph-metagenomics
python3 run_nextflow.py
