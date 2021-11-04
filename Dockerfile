FROM ubuntu:focal-20211006

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
  wget \
  git \
  tini \
  && apt-get clean

SHELL [ "/bin/bash", "--login", "-c" ]

RUN wget -nv https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
&& chmod +x Miniconda3-latest-Linux-x86_64.sh \
&& bash Miniconda3-latest-Linux-x86_64.sh -b \
&& rm Miniconda3-latest-Linux-x86_64.sh

ENV PATH=/root/miniconda3/bin:${PATH}

RUN conda update -y conda && conda install -y -c anaconda python=3.7 \
&& conda install -y -c conda-forge mamba \
&& conda clean -a -y

COPY speciesprimerenv.yaml /
RUN mamba update -y -n base -f speciesprimerenv.yaml && \
    mamba clean --all --yes

# install additional python dependencies
COPY requirements.txt /
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# create program directory
RUN mkdir /programs && mkdir /primerdesign && mkdir /blastdb && mkdir /programs/tmp
ENV PATH="/programs/:${PATH}"

ENV ac_cv_func_malloc_0_nonnull=yes
# libdg required by mfold
RUN cd /programs && wget -nv \
https://github.com/libgd/libgd/releases/download/gd-2.2.5/libgd-2.2.5.tar.gz \
&& tar xf libgd-2.2.5.tar.gz && cd libgd-2.2.5 && ./configure && make && make install \
&& echo "/usr/local/lib" >> /etc/ld.so.conf && ldconfig

# install mfold 3.6
RUN cd /programs && wget -nv \
http://www.unafold.org/download/mfold-3.6.tar.gz \
&& tar xf mfold-3.6.tar.gz \
&& cd mfold-3.6 && ./configure && make && make install

RUN cd /programs && git clone https://github.com/biologger/MFEprimer-py3.git \
&& cd MFEprimer-py3 && python3 setup.py install && python3 setup.py install_data

# remove archives
RUN cd /programs && rm *.tar.gz

# Remove Bug "Use of uninitialized value in require at .../Encode.pm line 61."
RUN enc2xs -C

ENV BLASTDB="/blastdb"
ENV BLAST_USAGE_REPORT=FALSE

# Create a non-root user
ARG username=primer
ARG uid=1000
ARG gid=100
ENV USER $username
ENV UID $uid
ENV GID $gid
ENV HOME /home/$USER
RUN adduser --disabled-password \
    --gecos "Non-root user" \
    --uid $UID \
    --gid $GID \
    --home $HOME \
    $USER
