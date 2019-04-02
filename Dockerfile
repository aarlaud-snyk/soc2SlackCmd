FROM ubuntu:16.04
MAINTAINER antoine@snyk.io

RUN mkdir -p /src
WORKDIR /src

RUN apt-get update && apt-get install -y \
  pdftk texlive-full
RUN apt-get update && apt-get install gcc python-setuptools python-dev libffi-dev -y
RUN apt-get update && apt-get install python-pip -y
RUN apt-get install curl -y
RUN pip install gsutil

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install nodejs -y

WORKDIR /workdir
COPY scripts/* /workdir/
RUN chmod a+x /workdir/*.sh
COPY IN.pdf /workdir
#COPY scripts/soc2-generate-and-upload.sh /workdir
COPY package.json /workdir
COPY index.js /workdir
RUN npm install

ENV PATH="/usr/bin/pdftk:${PATH}"
ENV NODE_ENV=production
#ENV GSUTILSECRETVOLUME=$GSUTILSECRETVOLUME
ENV BOTO_CONFIG=/etc/gsutil-secret-volume

#ENTRYPOINT ["/usr/bin/pdftk"]

#CMD ["node","workdir/index.js"]
CMD ["node","--version"]

#ENTRYPOINT ["pdftk"]
EXPOSE 8888/tcp

CMD ["node","index.js"]
