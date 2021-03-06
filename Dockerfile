FROM jupyter/minimal-notebook:63d0df23b673
MAINTAINER Grady Fitzpatrick <grady.fitzpatrick@unimelb.edu.au>

# Note:
# This repo forked from Brendan Rius' Jupyter C Kernel.

USER root

WORKDIR /tmp

COPY ./ jupyter_c_kernel/

# Install jupyter_c_kernel
RUN pip install --no-cache-dir jupyter_c_kernel/
RUN cd jupyter_c_kernel && install_c_kernel --user

# Add nbgrader to python environment and install other python modules.
RUN pip install --no-cache-dir nbgrader nbgitpuller pandas matplotlib seaborn numpy scipy sklearn sympy nose nltk graphviz lxml bs4 redis textdistance pyunpack patool pycryptodome
RUN jupyter nbextension install --sys-prefix --py nbgrader --overwrite
RUN jupyter nbextension enable --sys-prefix --py nbgrader
RUN jupyter serverextension enable --sys-prefix --py nbgrader

# To disable the Assignment List extension
#jupyter nbextension disable --sys-prefix assignment_list/main --section=tree
#jupyter serverextension disable --sys-prefix nbgrader.server_extensions.assignment_list

# To disable the Create Assignment extension
#jupyter nbextension disable --sys-prefix create_assignment/main

# To disable the Formgrader extension
#jupyter nbextension disable --sys-prefix formgrader/main --section=tree
#jupyter serverextension disable --sys-prefix nbgrader.server_extensions.formgrader

# To disable the Course List extension
RUN jupyter nbextension disable --sys-prefix course_list/main --section=tree
RUN jupyter serverextension disable --sys-prefix nbgrader.server_extensions.course_list

# Re-enable man pages
RUN sed -i '/path-exclude=\/usr\/share\/man\/*/c\#path-exclude=\/usr\/share\/man\/*' /etc/dpkg/dpkg.cfg.d/excludes

# Install GDB, valgrind and man pages, as well as 7z and 7z rar support.
# NOTE: the rar algorithm is proprietary so we need to add the multiverse repository
RUN apt-get update && apt-get install -y software-properties-common && add-apt-repository multiverse && apt-get update && apt-get install -y gdb valgrind manpages manpages-dev manpages-posix man less vim tar zip unzip enscript ghostscript p7zip-full p7zip-rar unrar

# Install curses, used for an assignment. =)
RUN apt-get update && apt-get install -y libncurses5-dev libncursesw5-dev graphviz

RUN /bin/bash jupyter_c_kernel/nbgrader_setup.sh /opt/conda/etc/jupyter/

WORKDIR /home/$NB_USER/

USER $NB_USER

RUN /bin/bash -c 'echo "ulimit -c 0" >> ~/.bashrc'
