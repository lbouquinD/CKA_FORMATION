#!/bin/bash  


function get_JSON_Pods() {
    name=$1
    namespace=$2
    result=$(kubectl get  po $name -n  $namespace -o  json)
    echo  $? 

}

get_JSON_Pods expod2 default  




