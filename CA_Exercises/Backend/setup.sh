#!/bin/bash
export PROJECT_HOME=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
MAMBA_EXE=bin/micromamba
MAMBA_BASE=$PROJECT_HOME/$MAMBA_EXE
export CONDA_PREFIX=$PROJECT_HOME/conda-env

# Install mamba if not installed
if [ ! -d ${CONDA_PREFIX} ]
then
    wget -qO- https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj $MAMBA_EXE
    
    $MAMBA_BASE create -y -p $CONDA_PREFIX 
    echo 'python ==3.7*' >> $CONDA_PREFIX/conda-meta/pinned
    $MAMBA_BASE install -y -p $CONDA_PREFIX -c litex-hub -c main \
            "openlane=2023.03.01_0_ge10820ec" \
            "open_pdks.sky130a=1.0.403_0_g12df12e" \
            "openroad=2.0_7070_g0264023b6" \
            "magic=8.3.382_0_g1044878" \
            "netgen=1.5.251_0_gd111fa0" \
            "yosys=0.27_23_g53c0a6b78"
    $MAMBA_BASE install -y -p $CONDA_PREFIX -c conda-forge git tcllib gdstk cairosvg pyyaml click pandas svgutils pip jupyterlab jupyterlab_execute_time matplotlib seaborn
    rm -f $CONDA_PREFIX/lib/libtinfo.so $CONDA_PREFIX/lib/libtinfo.so.6
fi

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib
export OPENLANE_ROOT=$CONDA_PREFIX/share/openlane
export PDK_ROOT=$CONDA_PREFIX/share/pdk
export PDK=sky130A
export STD_CELL_LIBRARY=sky130_fd_sc_hd
export STD_CELL_LIBRARY_OPT=sky130_fd_sc_hd
export TCLLIBPATH=$(find $CONDA_PREFIX/lib -type d -name tcllib*)
export PATH=$CONDA_PREFIX/bin:$PATH:$OPENLANE_ROOT:$OPENLANE_ROOT/scripts
export OPENLANE_LOCAL_INSTALL=1
