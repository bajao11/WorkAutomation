#!/bin/sh

#To execute the script: ./checkpatches.sh 6.6.10 US SERVICEBENCH-xxxxx
# Declare Variables
datetoday=`date +"%Y%m%d-%H%M%S"`
output_path=/home/serviceb/checkpatches/output
input_rel=$1
input_geo=$2
input_patch=$3

# Array of patches and region
arraypatches=( $3 $4 $5 $6 $7 $8 )
arrayregion=( AP EU US )

# Define Function
storetest(){
  if [ ! -z "$check_test" ]
  then
    echo -e "$i is already installed in Test $input_geo (more details below) \n $check_test" >> $patch_path/patch_$input_geo.txt
  else
    echo -e "$i is not installed in Test $input_geo" >> $patch_path/patch_$input_geo.txt
  fi
}

storepreprod(){
  if [ ! -z "$check_preprod" ]
  then
    echo -e "$i is already installed in Pre-Prod/UAT $input_geo (more details below) \n $check_preprod" >> $patch_path/patch_$input_geo.txt
  else
    echo -e "$i is not installed in Pre-Prod/UAT $input_geo" >> $patch_path/patch_$input_geo.txt
  fi
}

storeprod(){
  if [ ! -z "$check_prod" ]
  then
    echo -e "$i is already installed in Prod $input_geo (more details below) \n $check_prod" >> $patch_path/patch_$input_geo.txt
  else
    echo -e "$i is not installed in Prod $input_geo" >> $patch_path/patch_$input_geo.txt
  fi
}

usage(){
  echo -e "NAME \n\t checkpatches - A script that check patches if installed in other environment"
  echo -e "USAGE \n\t checkpatches <release> <region> <patch name> <patch name> ..."
  echo -e "OPTIONS \n\t release \n\t\t Release version such as 6.6.10, 6.6.11. \n\t region \n\t\t Define the region where you want to check the patch either AP,EU, US or ALL. \n\t patch name \n\t\t Define the patch name you want to check."
}


allregion(){
  mkdir $output_path/$datetoday
  patch_path=$output_path/$datetoday

  for input_geo in "${arrayregion[@]}"
  do
    echo "$input_geo"
    echo -e "\n\n####### OUTPUT #######" > $patch_path/patch_$input_geo.txt
    for i in "${arraypatches[@]}"
    do
      if [ $input_geo == AP ]
      then
        echo "Checking patch $i in Test $input_geo region"
        check_test=`ssh -q serviceb@LQASRDSJMST002V "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
        storetest

        echo "Checking patch $i in Prod $input_geo region"
        check_prod=`ssh -q serviceb@LPRSRDSJMST001V "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
        storeprod

      elif [ $input_geo == EU ]
      then
        echo "Checking patch $i in Test $input_geo region"
        check_test=`ssh -q serviceb@100.107.37.149 "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
        storetest

        echo "Checking patch $i in Preprod/UAT $input_geo region"
        check_preprod=`ssh -q serviceb@100.74.180.55 "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
        storepreprod

        echo "Checking patch $i in Prod $input_geo region"
        check_prod=`ssh -q serviceb@100.65.32.215 "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
        storeprod

      elif [ $input_geo == US ]
      then
        echo "Checking patch $i in Test $input_geo region"
        check_test=`ssh -q serviceb@LQASRDSBMST002V "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
        storetest

        echo "Checking patch $i in Preprod/UAT $input_geo region"
        check_preprod=`ssh -q serviceb@LPRSRDSBPPM001V "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
        storepreprod


        echo "Checking patch $i in Prod $input_geo region"
        check_prod=`ssh -q serviceb@LPRSRDSBMST005V "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
        storeprod

      else
        echo -e "Please check the details below for proper usage of the script. \n"
        usage

      fi
    done
  done
}
# Main Script
if [ ! -z "$input_rel" ] && [ ! -z "$input_geo" ] && [ ! -z "$input_patch" ]
then
  if [ $input_geo == ALL ]
  then
    echo "$input_geo"
    allregion

    for input_geo in "${arrayregion[@]}"
    do
      cat $patch_path/patch_$input_geo.txt
    done
  else
    # Clear and create content of patch
    mkdir $output_path/$datetoday
    patch_path=$output_path/$datetoday
    echo -e "\n\n####### OUTPUT #######" > $patch_path/patch_$input_geo.txt
    echo "Checking $input_geo Region"

    for i in "${arraypatches[@]}"
      do
        if [ $input_geo == AP ]
        then
          echo "Checking patch $i version $input_rel in Test $input_geo environment"
          check_test=`ssh -q serviceb@LQASRDSJMST002V "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
          #Call test function
          storetest

          echo "Checking patch $i version $input_rel in Prod $input_geo environment"
          check_prod=`ssh -q serviceb@LPRSRDSJMST001V "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
          #Call prod function
          storeprod
          echo -e "\n" >> $patch_path/patch_$input_geo.txt
        elif [ $input_geo == EU ]
        then
          echo "Checking patch $i version $input_rel in Test $input_geo environment"
          check_test=`ssh -q serviceb@100.107.37.149 "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
          #Call test function
          storetest

          echo "Checking patch $i version $input_rel in Pre-Prod/UAT $input_geo environment"
          check_preprod=`ssh -q serviceb@100.74.180.55 "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
          #Call preprod function
          storepreprod

          echo "Checking patch $i version $input_rel in Prod $input_geo environment"
          check_prod=`ssh -q serviceb@100.65.32.215 "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
          #Call prod function
          storeprod
          echo -e "\n" >> $patch_path/patch_$input_geo.txt
        elif [ $input_geo == US ]
        then
          echo "Checking patch $i version $input_rel in Test $input_geo environment"
          check_test=`ssh -q serviceb@LQASRDSBMST002V "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
          #Call test function
          storetest

          echo "Checking patch $i version $input_rel in Pre-Prod/UAT $input_geo environment"
          check_preprod=`ssh -q serviceb@LPRSRDSBPPM001V "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
          #Call preprod function
          storepreprod

          echo "Checking patch $i version $input_rel in Prod $input_geo environment"
          check_prod=`ssh -q serviceb@LPRSRDSBMST005V "cat /home/serviceb/website/patches/installs.log | grep $input_rel | grep $i"`
          #Call prod function
          storeprod
          echo -e "\n" >> $patch_path/patch_$input_geo.txt
        else
          #echo "Please check the parameters. To execute the script, ./checkpatches.sh <release> <region> <patch number>. Ex. ./checkpatches.sh 6.6.10 US SERVICEBENCH-112233"
          echo -e "Please check the details below for proper usage of the script. \n"
          usage
        fi
      done
      cat $patch_path/patch_$input_geo.txt
  fi
else
  echo -e "Please check the details below for proper usage of the script. \n"
  usage
fi