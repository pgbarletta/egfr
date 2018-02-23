#! /bin/bash
list=$(<pdbs.list)
#list="1XKK_A"
i=0
for file in $list
do
    echo -------- $file -------  
    
    i=`expr $i + 1`
    nonrot_pdb=nonrot_$file.pdb
    pdb=$file.pdb
    file_dis=${file}_dis
    file_hb2=${file}.hb2

#    file_h=${file}_h
#    file_h_norm=${file}_h_norm
#    file_dis=${file}_dis
    cutoff_a=10
    file_bf=bf_${file}
    file_bfcorr=bfcorr_${file}
    file_bfteo=bfteo_${file}
    file_colec=colec_${file}
    file_correl=correl_${file}
    file_freq=freq_${file}
    file_mods=modos_${file}
# estos son los nombres de los archivos de out q me va a g.rar 'epanmhs.exe'

#    ./edis.exe $pdb $file_dis
#    ./hbplus $pdb
#    cat $file_hb2 | awk 'NR>9 {print $1}' > tmp_1
#    cat $file_hb2 | awk 'NR>9 {print $3}' > tmp_2


    cd $file
    for refile in $list
    do
        if [[ $file == $refile ]] 
        then
            continue
        fi

        refile_mods=modos_${refile}
        refile_ord=${file}_${refile}_ord
        refile_nsub=${file}_${refile}_nsub

#        cp ../$refile/$refile_mods .
        ./emin.exe $file_mods $refile_mods 825 $refile_ord $refile_nsub
    done

#    ./epanmhs.exe $pdb $cutoff_a $file_bf $file_bfcorr $file_bfteo $file_colec $file_correl $file_freq $file_mods 

    cd ..
done
