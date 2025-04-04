# building a docker image with java and nextflow
# java is installed based on the dockerfile at https://github.com/AdoptOpenJDK/openjdk-docker/blob/master/11/jdk/ubuntu/Dockerfile.hotspot.releases.full
FROM nextflow/nextflow:24.10.5


RUN dnf install python3-pip -y
RUN dnf install python3-setuptools -y

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

