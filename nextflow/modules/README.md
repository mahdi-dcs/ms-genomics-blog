# Docker Containers

Docker images that are used in the PRODUCTION environment are downloaded from the origin repository and stored with the same tag in the Azure Private Registry to provide a secure means for using these software packages. In total 3.66GiB of storage is used in the Container Registry.

```s

RESOURCE_GROUP="providencehealth-cc-prd-rg-genomics-01"
ACR="m3d83"
ACR="m3d83"

az acr login -g $RESOURCE_GROUP -n $ACR


# Combine Fastq:

ORG_IMAGE="ontresearch/wf-artic:shaa5485f2d1c9085c23b266273556a4ce01e5e0dd9"
IMAGE_NAME="ontresearch-wf-artic"
TAG="shaa5485f2d1c9085c23b266273556a4ce01e5e0dd9"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG


# alignment


ORG_IMAGE='quay.io/biocontainers/minimap2:2.17--hed695b0_3'
IMAGE_NAME="biocontainers-minimap2"
TAG="2.17--hed695b0_3"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG


# annotation_extractfield


ORG_IMAGE="quay.io/biocontainers/snpsift:4.3.1t--hdfd78af_3"
IMAGE_NAME="biocontainers-snpsift"
TAG="4.3.1t--hdfd78af_3"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG


# bam_generation

ORG_IMAGE="quay.io/biocontainers/samtools:1.17--h00cdaf9_0"
IMAGE_NAME="biocontainers-samtools"
TAG="1.17--h00cdaf9_0"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG


# blast

ORG_IMAGE="quay.io/biocontainers/blast:2.13.0--hf3cf87c_0"
IMAGE_NAME="biocontainers-blast"
TAG="2.13.0--hf3cf87c_0"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG


# call_annotation

ORG_IMAGE="quay.io/biocontainers/snpeff:5.1--hdfd78af_2"
IMAGE_NAME="biocontainers-snpeff"
TAG="5.1--hdfd78af_2"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG


# call_deletion

ORG_IMAGE="quay.io/biocontainers/medaka:1.4.4--py38h130def0_0"
IMAGE_NAME="biocontainers-medaka"
TAG="1.4.4--py38h130def0_0"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG


# call_snvs

ORG_IMAGE="quay.io/biocontainers/lofreq:2.1.5--py38h794fc9e_10"
IMAGE_NAME="biocontainers-lofreq"
TAG="2.1.5--py38h794fc9e_10"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG



# coverage


ORG_IMAGE="quay.io/biocontainers/mosdepth:0.3.3--hdfd78af_1"
IMAGE_NAME="biocontainers-mosdepth"
TAG="0.3.3--hdfd78af_1"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG



# dumpsoftwareversions


ORG_IMAGE="quay.io/biocontainers/multiqc:1.15--pyhdfd78af_0"
IMAGE_NAME="biocontainers-multiqc"
TAG="1.15--pyhdfd78af_0"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG


# fastp


ORG_IMAGE="quay.io/biocontainers/fastp:0.23.2--h79da9fb_0"
IMAGE_NAME="biocontainers-fastp"
TAG="0.23.2--h79da9fb_0"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG

# fastqc


ORG_IMAGE="quay.io/biocontainers/fastqc:0.11.9--0"
IMAGE_NAME="biocontainers-fastqc"
TAG="0.11.9--0"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG

# multiqc


ORG_IMAGE="quay.io/biocontainers/multiqc:1.25--pyhdfd78af_0"
IMAGE_NAME="biocontainers-multiqc"
TAG="1.25--pyhdfd78af_0"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG



# plot_coverage_region


ORG_IMAGE="quay.io/biocontainers/mulled-v2-ad9dd5f398966bf899ae05f8e7c54d0fb10cdfa7:05678da05b8e5a7a5130e90a9f9a6c585b965afa-0"
IMAGE_NAME="biocontainers-mulled-v2-ad9dd5f398966bf899ae05f8e7c54d0fb10cdfa7"
TAG="05678da05b8e5a7a5130e90a9f9a6c585b965afa-0"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG



# seqtk


ORG_IMAGE="quay.io/biocontainers/seqtk:1.4--he4a0461_1"
IMAGE_NAME="biocontainers-seqtk"
TAG="1.4--he4a0461_1"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG



# variant_long_table


ORG_IMAGE="quay.io/biocontainers/mulled-v2-77320db00eefbbf8c599692102c3d387a37ef02a:08144a66f00dc7684fad061f1466033c0176e7ad-0"
IMAGE_NAME="biocontainers-mulled-v2-77320db00eefbbf8c599692102c3d387a37ef02a"
TAG="08144a66f00dc7684fad061f1466033c0176e7ad-0"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG


# vcf_concat

ORG_IMAGE="quay.io/biocontainers/bcftools:1.17--haef29d1_0"
IMAGE_NAME="biocontainers-bcftools"
TAG="1.17--haef29d1_0"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG

# vcg_uniq

ORG_IMAGE="quay.io/biocontainers/vcflib:1.0.3--hecb563c_1"
IMAGE_NAME="biocontainers-vcflib"
TAG="1.0.3--hecb563c_1"

docker pull $ORG_IMAGE
docker tag $ORG_IMAGE $ACR/$IMAGE_NAME:$TAG
docker push $ACR/$IMAGE_NAME:$TAG

echo $ACR/$IMAGE_NAME:$TAG

```


Notes:

- This command was used as the start task. for those tasks that image was downloaded in the start task, nextflow would work iff the command was issued locally! when the same command and config used with the nextflow image from the web app, it didn't work! 
    ```s
     && curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash && az login --identity --username /subscriptions/3ecb3418-1581-41ff-b0c4-e88aca195513/resourceGroups/providencehealth-cc-prd-rg-genomics-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/genomics-batch-identity-prd && az acr login --name phcccgenacrprd && docker pull m3d83/ontresearch-wf-artic:20241129pull && docker pull m3d83/biocontainers-fastp:0.23.2--h79da9fb_0 && docker pull m3d83/biocontainers-fastqc:0.11.9--0
    ```