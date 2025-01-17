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

ARG repo
ARG arch=amd64
ARG python=3.6
FROM ${repo}:${arch}-conda-python-${python}

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -y -q && \
    apt-get install -y -q --no-install-recommends \
        odbc-postgresql \
        postgresql \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install turbodbc dependencies from conda-forge
RUN conda install -c conda-forge \
        pybind11 \
        pytest-cov \
        mock \
        unixodbc && \
    conda clean --all

RUN service postgresql start && \
    sudo -u postgres psql -U postgres -c \
        "CREATE DATABASE test_db;" && \
    sudo -u postgres psql -U postgres -c \
        "ALTER USER postgres WITH PASSWORD 'password';"

ARG turbodbc=latest
RUN git clone --recurse-submodules https://github.com/blue-yonder/turbodbc /turbodbc && \
    if [ "${turbodbc}" = "master" ]; then \
        git -C /turbodbc checkout master; \
    elif [ "${turbodbc}" = "latest" ]; then \
        git -C /turbodbc checkout $(git describe --tags); \
    else \
        git -C /turbodbc checkout ${turbodbc}; \
    fi

ENV TURBODBC_TEST_CONFIGURATION_FILES "query_fixtures_postgresql.json"
