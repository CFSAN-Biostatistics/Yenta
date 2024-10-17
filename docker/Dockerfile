# CSP2 Dockerfile
# Based on StaPH-B's Dockerfile for BEDTools, MUmmer, and Skesa
# Thanks to Erin Young, Curtis Kapsak, John Arnn, and the StaPH-B team
# https://github.com/StaPH-B/docker-builds/blob/master/bedtools/2.31.1/Dockerfile
# https://github.com/StaPH-B/docker-builds/blob/master/mummer/4.0.0/Dockerfile
# https://github.com/StaPH-B/docker-builds/blob/master/skesa/2.4.0/Dockerfile

ARG CSP2_VER="0.9.0"
ARG BEDTOOLS_VER="2.31.1"
ARG MUMMER_VER="4.0.0"
ARG SKESA_VER="2.4.0"
ARG MASH_VER="2.3"
ARG BBMAP_VER="38.90"
ARG PYTHON_VER="3.8"

FROM ubuntu:focal AS build

ARG BEDTOOLS_VER
ARG MUMMER_VER
ARG SKESA_VER
ARG MASH_VER
ARG BBMAP_VER
ARG PYTHON_VER

WORKDIR /build

# to prevent tzdata from asking for a region during apt updates; ARG so that variable only 
# persists at buildtime
# from https://github.com/StaPH-B/docker-builds/blob/master/mummer/4.0.0/Dockerfile
ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata \
    gpg-agent \
    software-properties-common \
    build-essential \
    zlib1g-dev \
    libghc-bzlib-dev \
    liblzma-dev \
    wget \
    ca-certificates 

RUN add-apt-repository 'ppa:deadsnakes/ppa' && apt-get update && apt-get install -y --no-install-recommends \
    python${PYTHON_VER} \
#    python${PYTHON_VER}-pip \
#    python${PYTHON_VER}-full \
    python${PYTHON_VER}-dev \
    python${PYTHON_VER}-venv && \
    python${PYTHON_VER} -m venv --copies /opt/venv


ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir -U pandas~=1.2.0 pybedtools refchooser scikit-learn

ADD https://github.com/arq5x/bedtools2/archive/refs/tags/v${BEDTOOLS_VER}.tar.gz .
ADD https://github.com/mummer4/mummer/releases/download/v${MUMMER_VER}rc1/mummer-${MUMMER_VER}rc1.tar.gz .
ADD https://github.com/ncbi/SKESA/releases/download/${SKESA_VER}/skesa.centos.7.7 .
ADD https://github.com/ncbi/SKESA/releases/download/${SKESA_VER}/gfa_connector.centos7.7 .
ADD https://github.com/ncbi/SKESA/releases/download/${SKESA_VER}/kmercounter.centos7.7 .
ADD https://github.com/marbl/Mash/releases/download/v${MASH_VER}/mash-Linux64-v${MASH_VER}.tar .

# Install BEDTools
# per https://github.com/StaPH-B/docker-builds/blob/master/bedtools/2.31.1/Dockerfile
# python3 required when compiling via `make` command for creating old CLI executables
# dependencies listed here (albeit for v2.30.0, still should be identical): https://packages.ubuntu.com/jammy/bedtools
# requires libghc-bzlib-dev, build-essential, zlib1g-dev, and a few others
# 'make install' should place binary executable files in /usr/local/bin
RUN tar -xzf v${BEDTOOLS_VER}.tar.gz && \
    rm v${BEDTOOLS_VER}.tar.gz && \
   cd bedtools2-${BEDTOOLS_VER} && \
   make && \
   make install 

 # Install mummer
 # per https://github.com/StaPH-B/docker-builds/blob/master/mummer/4.0.0/Dockerfile
RUN tar -xvf mummer-${MUMMER_VER}rc1.tar.gz && \
    rm mummer-${MUMMER_VER}rc1.tar.gz && \
    cd mummer-${MUMMER_VER}rc1 && \
    ./configure --prefix=/usr/local && \
    make && \
    make install && \
    ldconfig

# # Install Skesa
# # per https://github.com/StaPH-B/docker-builds/blob/master/skesa/2.4.0/Dockerfile
# # get skesa, gfa_connector, and kmercounter binaries, rename them
RUN mkdir skesa && \
    cd skesa && \
    mv /build/skesa.centos.7.7 skesa && \
    mv /build/gfa_connector.centos7.7 gfa_connector && \
    mv /build/kmercounter.centos7.7 kmercounter && \
    chmod +x skesa gfa_connector kmercounter && \
    mv skesa gfa_connector kmercounter /usr/local/bin

# Install Mash
RUN tar -xvf mash-Linux64-v${MASH_VER}.tar && \
    mv mash-Linux64-v${MASH_VER}/mash /usr/local/bin

# Install BBMap
RUN wget -O BBMap_${BBMAP_VER}.tar.gz https://sourceforge.net/projects/bbmap/files/BBMap_${BBMAP_VER}.tar.gz/download && \
    tar -xvf BBMap_${BBMAP_VER}.tar.gz && \
    mv bbmap/* /usr/local/bin


FROM ubuntu:focal AS app

ARG CSP2_VER
ARG CSP2_BRANCH="main"
ARG PYTHON_VER

LABEL base.image="ubuntu:focal"
LABEL version=${CSP2_VER}
LABEL software="CSP2"
LABEL software.version=${CSP2_VER}
LABEL description="a Nextflow pipeline for rapid, accurate SNP distance estimation from assembly data"
LABEL website="https://github.com/CFSAN-Biostatistics/CSP2"
LABEL licence="https://github.com/CFSAN-Biostatistics/CSP2/blob/main/LICENSE"
LABEL maintainer="Robert Literman"
LABEL maintainer.email="Robert.Literman@fda.hhs.gov"
LABEL maintainer.organization="FDA/CFSAN/Biostatistics"
LABEL maintainer2="Justin Payne"
LABEL maintainer2.email="Justin.Payne@fda.hhs.gov"
LABEL maintainer2.organization="FDA/CFSAN/Biostatistics"

WORKDIR /root/.nextflow
WORKDIR /app

# copy in all executable files from builder stage to final app stage
COPY --from=build /usr/local/bin /usr/local/bin

# Lots of perl nonsense
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/libexec/mummer /usr/local/libexec/mummer
COPY --from=build /usr/lib/x86_64-linux-gnu/perl /usr/lib/x86_64-linux-gnu/perl
COPY --from=build /usr/local/share /usr/local/share
COPY --from=build /usr/share /usr/share
COPY --from=build /opt/venv /opt/venv
COPY --from=build /usr/bin/make /usr/local/bin/make


# Python stuff
COPY --from=build /usr/lib/python${PYTHON_VER} /usr/lib/python${PYTHON_VER}


#Install JRE
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    openjdk-17-jre-headless \
    curl

# Install Nextflow
# per https://www.nextflow.io/docs/latest/getstarted.html
RUN export CAPSULE_LOG=debug && curl -s https://get.nextflow.io | bash && \
    chmod +x nextflow && \
    mv nextflow /usr/local/bin && \
    nextflow run hello

COPY Makefile .

# set PATH, set perl locale settings for singularity compatibility
ENV PATH="/opt/venv/bin:/usr/local/bin:/skesa:$PATH" \
    LC_ALL=C \
    NXF_OFFLINE='true'

ADD https://github.com/CFSAN-Biostatistics/CSP2.git#${CSP2_BRANCH}:bin ./bin
ADD https://github.com/CFSAN-Biostatistics/CSP2.git#${CSP2_BRANCH}:conf ./conf
ADD https://github.com/CFSAN-Biostatistics/CSP2.git#${CSP2_BRANCH}:subworkflows ./subworkflows
ADD https://raw.githubusercontent.com/CFSAN-Biostatistics/CSP2/${CSP2_BRANCH}/CSP2.nf ./CSP2.nf
ADD https://raw.githubusercontent.com/CFSAN-Biostatistics/CSP2/${CSP2_BRANCH}/nextflow.config ./nextflow.config


FROM app AS pretest

# set PATH, set perl locale settings for singularity compatibility
ENV PATH="/opt/venv/bin:/usr/local/bin:/skesa:$PATH" \
    LC_ALL=C \
    NXF_OFFLINE='true'

#Alternate test data directory
ADD https://github.com/crashfrog/CSP2.git#main:assets assets/
# ADD https://github.com/crashfrog/CSP2.git#main:Test_Output Test_Output/


# Test MUmmer installation
# per https://github.com/StaPH-B/docker-builds/blob/master/mummer/4.0.0/Dockerfile

ADD https://mummer4.github.io/tutorial/exampleFiles/2.1/in/H_pylori26695_Eslice.fasta .
ADD https://mummer4.github.io/tutorial/exampleFiles/2.1/in/H_pyloriJ99_Eslice.fasta .
ADD https://mummer4.github.io/tutorial/exampleFiles/2.2/in/B_anthracis_Mslice.fasta .
ADD https://mummer4.github.io/tutorial/exampleFiles/2.2/in/B_anthracis_contigs.fasta .
ADD http://mummer.sourceforge.net/examples/data/H_pylori26695_Eslice.fasta .
ADD http://mummer.sourceforge.net/examples/data/H_pyloriJ99_Eslice.fasta .
ADD https://raw.githubusercontent.com/artic-network/artic-ncov2019/master/primer_schemes/nCoV-2019/V5.3.2/SARS-CoV-2.primer.bed ./V5.3.2.artic.bed
ADD https://raw.githubusercontent.com/artic-network/artic-ncov2019/master/primer_schemes/nCoV-2019/V4.1/SARS-CoV-2.primer.bed ./V4.1.artic.bed

FROM pretest AS test

# Test MASH

RUN nucmer -h && \
  promer -h && \
  mummer -mum -b -c H_pylori26695_Eslice.fasta H_pyloriJ99_Eslice.fasta > mummer.mums && \
  nucmer  -c 100 -p nucmer B_anthracis_Mslice.fasta B_anthracis_contigs.fasta && \
  show-snps -C nucmer.delta > nucmer.snps && \
  promer -p promer_100 -c 100  H_pylori26695_Eslice.fasta H_pyloriJ99_Eslice.fasta

# Test bedtools installation
# check help options and version
RUN bedtools --help && \
    bedtools --version

# downloads two bedfiles for ARTIC SARS-CoV-2 artic schemes, fixes their formatting, uses bedtools sort, intersect, and merge
# per https://github.com/StaPH-B/docker-builds/blob/master/bedtools/2.31.1/Dockerfile
RUN awk '{print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6}' V5.3.2.artic.bed > V5.3.2.unsorted.bed && \
    bedtools sort -i V5.3.2.unsorted.bed > V5.3.2.bed && \
    awk '{print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6}' V4.1.artic.bed   > V4.1.bed   && \
    bedtools intersect -a V5.3.2.bed -b V4.1.bed > intersect_test.bed && \
    mergeBed -i V5.3.2.bed > merged_test.bed && \
    head intersect_test.bed merged_test.bed

RUN /bin/bash -c 'make test'

FROM app AS release

ARG CSP2_VER
ARG BEDTOOLS_VER
ARG MUMMER_VER
ARG SKESA_VER
ARG MASH_VER
ARG BBMAP_VER
ARG PYTHON_VER
ENV CSP2_VER=${CSP2_VER}
ENV BEDTOOLS_VER=${BEDTOOLS_VER}
ENV MUMMER_VER=${MUMMER_VER}
ENV SKESA_VER=${SKESA_VER}
ENV MASH_VER=${MASH_VER}
ENV BBMAP_VER=${BBMAP_VER}
ENV PYTHON_VER=${PYTHON_VER}

# set PATH, set perl locale settings for singularity compatibility
ENV PATH="/opt/venv/bin:/usr/local/bin:/skesa:$PATH" \
    LC_ALL=C \
    NXF_OFFLINE='true'

ENTRYPOINT ["make", "--makefile=/app/Makefile"]