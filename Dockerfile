FROM mambaorg/micromamba

ENV TZ=Europe/Zurich
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL maintainer="biologger@protonmail.com"

RUN apt-get update && apt-get install -y \
	apt-utils \
	nano \
	texlive-font-utils \
	curl \
  unzip \
  parallel \
  build-essential \
	gfortran \
	&& apt-get clean

SHELL [ "/bin/bash", "--login", "-c" ]

# Create a non-root user
ARG username=primer
ARG uid=1000
ARG gid=100
ENV USER $username
ENV UID $uid
ENV GID $gid
ENV HOME /home/$USERRUN adduser --disabled-password \
    --gecos "Non-root user" \
    --uid $UID \
    --gid $GID \
    --home $HOME \
    $USER

COPY speciesprimerenv.yaml /
RUN micromamba install -y -n base -f speciesprimerenv.yaml && \
    micromamba clean --all --yes

# install additional python dependencies
COPY requirements.txt /
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# create program directory
RUN mkdir /programs && mkdir /primerdesign && mkdir /blastdb && mkdir /programs/tmp
ENV PATH="/programs/:${PATH}"

# libdg required by mfold
RUN cd /programs && wget -nv \
https://github.com/libgd/libgd/releases/download/gd-2.2.5/libgd-2.2.5.tar.gz \
&& tar xf libgd-2.2.5.tar.gz && cd libgd-2.2.5 && ./configure && make && make install

# install mfold 3.6
RUN cd /programs && wget -nv \
http://www.unafold.org/download/mfold-3.6.tar.gz \
&& tar xf mfold-3.6.tar.gz \
&& cd mfold-3.6 && ./configure && make && make install

# install frontail
RUN cd /programs && wget -nv \
https://github.com/mthenw/frontail/releases/download/v4.9.2/frontail-linux \
&& chmod +x frontail-linux

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "base", "/bin/bash"]
