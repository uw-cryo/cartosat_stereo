#! /bin/bash

set -e
map=true

threads=32
res=2.5
ndv=0

dir=$1
cd $dir

lfs setstripe -c $threads .

#Bundle adjustment
#ba_prefix=ba/out

proj=EPSG:32644
rpcdem=/nobackup/deshean/rpcdem/hma/srtm1/hma_srtm_gl1.vrt
k=21
k=35

a=$(ls *_A.tif)
am=${a%.*}_MET.TXT
f=$(ls *_F.tif)
fm=${f%.*}_MET.TXT

if [ ! -d rpcbin ] ; then
    mkdir rpcbin
    mv ${a%.*}_RPC.TXT ${f%.*}_RPC.TXT rpcbin/
    ln -s ${a%.*}_RPC_ORG.TXT ${a%.*}_RPC.TXT
    ln -s ${f%.*}_RPC_ORG.TXT ${f%.*}_RPC.TXT
fi

#extent='-1393680 -21760 -1063240 433520'
#proj4=$(gdalsrsinfo -o proj4 $proj)
#extent=$(../cartosat_stereo_int.py BANDA.tif BANDF.tif $proj4) 
extent=$(cartosat_stereo_int.py $a $f 32644) 

spm=3
corrkernel=$k
rfnekernel=$k
max_lv=3
timeout=1200
erode_px=1024

stereo_opt=""
stereo_opt+=" -t rpc"
stereo_opt+=" --threads $threads"
stereo_opt+=" --individually-normalize"
stereo_opt+=" --subpixel-mode $spm"
stereo_opt+=" --corr-kernel $corrkernel $corrkernel"
stereo_opt+=" --subpixel-kernel $rfnekernel $rfnekernel"
stereo_opt+=" --corr-max-levels $max_lv"
stereo_opt+=" --corr-timeout $timeout"
stereo_opt+=" --filter-mode 1"
stereo_opt+=" --erode-max-size $erode_px"

outdir=dem_ortho_${res}m
if [ ! -d $outdir ]; then
    mkdir -pv $outdir
fi
lfs setstripe -c $threads $outdir

#Extract relevant metadata
d=$(grep DateOfPass $fm | awk -F'=' '{print $2}')
t=$(grep SceneCenterTime $fm | awk -F'=' '{print $2}')
id1=$(grep ProductID $fm | awk -F'=' '{print $2}')
id2=$(grep ProductID $am | awk -F'=' '{print $2}')

#ts=20141027_0526
ts=$(cartosat_date.py $d $t)

prefix=${ts}_${id1}_${id2}

if $map ; then
    stereo_opt+=" --alignment-method None"
    if [ ! -e ${a%.*}_ortho_${res}m.tif ] ; then 
        echo "Mapping input images"
        #The ln step is necessary so ASP can find RPCs in original file
        #GDAL reads the RPC.txt
        #--t_projwin $extent
        parallel -v "mapproject --threads $threads -t rpc --nodata-value $ndv $rpcdem {} {.}_RPC.TXT --t_srs $proj --tr $res {.}_ortho_${res}m.tif; ln -s {.}_RPC.TXT {.}_ortho_${res}m_RPC.TXT" ::: $a $f
    fi

    #--bundle-adjust-prefix $ba_prefix 
    stereo $stereo_opt ${a%.*}_ortho_${res}m.tif ${f%.*}_ortho_${res}m.tif ${a%.*}_ortho_${res}m_RPC.TXT ${f%.*}_ortho_${res}m_RPC.TXT $outdir/$prefix $rpcdem
else
    #Unmapped inputs
    stereo $stereo_opt $a $f $outdir/$prefix
fi

dem_ndv=-9999
base_dem_opt+="--nodata-value $dem_ndv"
base_dem_opt+=" --remove-outliers --remove-outliers-params 75.0 3.0"
base_dem_opt+=" --threads 4"
#base_dem_opt+=" --t_srs \"$proj\""
base_dem_opt+=" --t_srs $proj"
dem_res_list="10 40"
parallel "point2dem $base_dem_opt --tr {} -o $outdir/${prefix}_{}m $outdir/${prefix}-PC.tif" ::: $dem_res_list

