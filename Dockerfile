FROM ubuntu:16.04

MAINTAINER biologger

RUN apt-get update && apt-get install -y \
	apt-utils \
	nano \
	texlive-font-utils \
	wget \
	git \
	unzip \
	build-essential \
	gfortran \
	perl \
	bioperl \
	aragorn \
	prodigal \
	parallel \
	hmmer \
	infernal \
	barrnap \
	bedtools \
	cd-hit \
	mcl \
	gawk \
	cpanminus \
	prank \
	mafft \
	libdatetime-perl \
	libxml-simple-perl \
	libdigest-md5-perl \
	libjson-perl \
	default-jre \
	emboss \
	python3-pip \
	python3-dev \
	python-pip \
	tzdata \
	&& apt-get clean


# create program directory
RUN mkdir /home/programs && mkdir /home/primerdesign
ENV PATH="/home/programs/:${PATH}"

RUN cpanm -f Bio::Roary

# install python dependencies
COPY requirements.txt /
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN pip2 install --upgrade pip
RUN pip2 install psutil

# install prokka
RUN cd /home/programs && git clone https://github.com/tseemann/prokka.git \
&& prokka/bin/prokka --setupdb
ENV PATH="/home/programs/prokka/bin/:${PATH}"

# install latest ncbi-blast
RUN cd /home/programs && mkdir ncbi-blast && wget -nv -r --no-parent --no-directories \
-A 'ncbi-blast-*+-x64-linux.tar.gz' ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ \
&& tar -xzf ncbi-blast-*+-x64-linux.tar.gz -C ncbi-blast --strip-components 1
ENV PATH="/home/programs/ncbi-blast/bin/:${PATH}"
ENV BLASTDB="/home/blastdb"

# install primer3
RUN cd /home/programs && git clone https://github.com/primer3-org/primer3.git primer3 \
&& cd primer3/src && make && make test
ENV PATH="/home/programs/primer3/:${PATH}"

# libdg required by mfold
RUN cd /home/programs && wget -nv \
https://github.com/libgd/libgd/releases/download/gd-2.2.5/libgd-2.2.5.tar.gz \
&& tar xf libgd-2.2.5.tar.gz && cd libgd-2.2.5 && ./configure && make && make install

# install mfold 3.6
RUN cd /home/programs && wget -nv \
http://unafold.rna.albany.edu/download/mfold-3.6.tar.gz \
&& tar xf mfold-3.6.tar.gz \
&& cd mfold-3.6 && ./configure && make && make install

# install MFEPrimer2.0
RUN cd /home/programs && wget -nv \
https://github.com/quwubin/MFEprimer/archive/v2.0.tar.gz \
&& tar xf v2.0.tar.gz

ENV PATH="/home/programs/MFEprimer-2.0/:${PATH}"

# install tbl2asn
RUN cd /home/programs && wget -nv \
ftp://ftp.ncbi.nih.gov/toolbox/ncbi_tools/converters/by_program/tbl2asn/linux.tbl2asn.gz \
&& gunzip linux.tbl2asn.gz

# install FastTreeMP
RUN cd /home/programs && wget -nv \
http://microbesonline.org/fasttree/FastTree.c \
&& gcc -DOPENMP -fopenmp -O3 -finline-functions -funroll-loops -Wall -o fasttree FastTree.c -lm

# install frontail
RUN cd /home/programs && wget -nv \
https://github.com/mthenw/frontail/releases/download/v4.5.4/frontail-linux \
&& chmod +x frontail-linux

# remove archives
RUN cd /home/programs && rm *.tar.gz
