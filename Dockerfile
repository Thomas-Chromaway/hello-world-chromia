FROM mcr.microsoft.com/devcontainers/java:1-21-bullseye

ARG INSTALL_MAVEN="true"
ARG MAVEN_VERSION=""

ARG INSTALL_GRADLE="false"
ARG GRADLE_VERSION=""

RUN if [ "${INSTALL_MAVEN}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/sdkman/bin/sdkman-init.sh && sdk install maven \"${MAVEN_VERSION}\""; fi \
    && if [ "${INSTALL_GRADLE}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/sdkman/bin/sdkman-init.sh && sdk install gradle \"${GRADLE_VERSION}\""; fi

USER root
RUN apt-get update

# NPM as everything seems to need that
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash
RUN apt-get install -y nodejs

# Postgres
RUN apt-get install -y postgresql-client postgresql postgresql-contrib
RUN mkdir -p /var/lib/postgresql/data
RUN echo "sudo service postgresql start" >> ~vscode/.profile
# Postchain default database 
RUN service postgresql start && sudo -u postgres psql -U postgres -c "CREATE DATABASE postchain WITH TEMPLATE = template0 LC_COLLATE = 'C.UTF-8' LC_CTYPE = 'C.UTF-8' ENCODING 'UTF-8';" -c "CREATE ROLE postchain LOGIN ENCRYPTED PASSWORD 'postchain'; GRANT ALL ON DATABASE postchain TO postchain;"
# Add default database, user, and password into the global environment
ENV PGHOST localhost
ENV PGPORT 5432
ENV PGDATABASE postchain
ENV PGUSER postchain
ENV PGPASSWORD postchain

# Install CHR and PMC
RUN curl -fsSL https://apt.chromia.com/chromia.gpg > /usr/share/keyrings/chromia.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/chromia.gpg] https://apt.chromia.com stable main" | tee /etc/apt/sources.list.d/chromia.list
RUN apt-get update
RUN apt-get download chr:amd64
RUN dpkg --force-architecture --ignore-depends=chr -i chr_*.deb || true; rm chr_*_amd64.deb
RUN apt-get download pmc:amd64
RUN dpkg --force-architecture -i pmc_*.deb && rm pmc_*_amd64.deb
