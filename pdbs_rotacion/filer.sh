#! /bin/bash
list=$(<pdbs.list)
i=0
for file in $list
do
        echo -------- $file -------  
        
        i=`expr $i + 1`
        pdb=$file.pdb

        mv $pdb $file/
       
done