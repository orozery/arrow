# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

ARG arch=amd64
FROM ${arch}/ubuntu:18.04

# arch is unset after the FROM statement, so need to define it again
ARG arch=amd64
ARG prefix=/opt/conda

# install build essentials
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -y -q && \
    apt-get install -y -q wget tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH=${prefix}/bin:$PATH \
    CONDA_PREFIX=${prefix}
# install conda and minio
COPY ci/scripts/install_conda.sh \
     ci/scripts/install_minio.sh \
     /arrow/ci/scripts/
RUN /arrow/ci/scripts/install_conda.sh ${arch} linux latest ${prefix} && \
    /arrow/ci/scripts/install_minio.sh ${arch} linux latest ${prefix}

# install the required conda packages
COPY ci/conda_env_cpp.yml \
     ci/conda_env_gandiva.yml \
     ci/conda_env_unix.yml \
     /arrow/ci/
RUN conda install -q \
        --file arrow/ci/conda_env_unix.yml \
        --file arrow/ci/conda_env_cpp.yml \
        --file arrow/ci/conda_env_gandiva.yml \
        git compilers && \
    conda clean --all

ENV ARROW_S3=ON \
    ARROW_ORC=ON \
    ARROW_GANDIVA=ON \
    ARROW_PARQUET=ON \
    ARROW_PLASMA=ON \
    ARROW_FLIGHT=ON \
    ARROW_WITH_ZLIB=ON \
    ARROW_WITH_LZ4=ON \
    ARROW_WITH_BZ2=ON \
    ARROW_WITH_ZSTD=ON \
    ARROW_WITH_SNAPPY=ON \
    ARROW_WITH_BROTLI=ON \
    ARROW_BUILD_TESTS=ON \
    ARROW_DEPENDENCY_SOURCE=CONDA \
    ARROW_HOME=$CONDA_PREFIX \
    PARQUET_HOME=$CONDA_PREFIX
