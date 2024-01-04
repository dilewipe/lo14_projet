#! /bin/bash

# Ce script implÃ©mente un serveur.  
# Le script doit Ãªtre invoquÃ© avec l'argument :                                                              
# PORT   le port sur lequel le serveur attend ses clients  

if [ $# -ne 1 ]; then
    echo "usage: $(basename $0) PORT"
    exit -1
fi

PORT="$1"

# DÃ©claration du tube

FIFO="/tmp/$USER-fifo-$$"

# Il faut dÃ©truire le tube quand le serveur termine pour Ã©viter de
# polluer /tmp.  On utilise pour cela une instruction trap pour Ãªtre sur de
# nettoyer mÃªme si le serveur est interrompu par un signal.

function nettoyage() { rm -f "$FIFO"; }
trap nettoyage EXIT

# on crÃ©e le tube nommÃ©

[ -e "FIFO" ] || mkfifo "$FIFO"


function accept-loop() {
    while true; do
        interaction < "$FIFO" | netcat -l -p "$PORT" > "$FIFO"
    done
}

# La fonction interaction lit les commandes du client sur entrÃ©e standard 
# et envoie les rÃ©ponses sur sa sortie standard. 
#
#       CMD arg1 arg2 ... argn                   
#                     
# alors elle invoque la fonction :
#                                                                            
#         commande-CMD arg1 arg2 ... argn                                      
#                                                                              
# si elle existe; sinon elle envoie une rÃ©ponse d'erreur.                     

function interaction() {
    local cmd args
    while true; do
        read cmd args || exit -1
        fun="commande-$cmd"
        if [ "$(type -t $fun)" = "function" ]; then
            $fun $args
        else
            commande-non-comprise $fun $args
        fi
    done
}

# Les fonctions implÃ©mentant les diffÃ©rentes commandes du serveur


function commande-non-comprise () {
   echo "Le serveur ne peut pas interprÃ©ter cette commande"
}


function commande-exit () {

pkill -x nc > /dev/null 2>&1

}
function commande-list () {

 echo "$(ls -p /home/archives | grep -v /)"
 pkill -x nc > /dev/null 2>&1

}

function commande-create () {

archive=$1

if [ -f $archive ]; then

        echo "vsh: Le fichier '$archive' existe dÃ©jÃ  sur le serveur"
else

ligne="${*:2}"

#touch $archive

echo -e "$(echo "$ligne" | sed 's/\%%/\\n/g')" | sed 's/Â£Â£/\\/g'> /home/archives/$archive

fichlong=$(wc -l $archive | cut -d' ' -f1)
for ((i=1;i<=$fichlong;i++)); do
                sed -i "${i}s/^ //g" $archive
        done


fi

pkill -x nc > /dev/null 2>&1



}

function commande-extract () {

dir=$(ls -p /home/archives | grep -v /)
exist=0

for i in $dir
do
        if [ "$1" == "$i" ]; then 

               exist=1
        fi
done

if [ "$exist" -eq 1 ]; then


        cat /home/archives/$1


else
        echo "vsh: Le fichier '$1' est introuvable"
fi
pkill -x nc > /dev/null 2>&1


}


function commande-browse () {




if [ ! -r /home/archives/$1 ]; then

        echo "vsh: Le fichier '$1' est introuvable ou illisible"

else
 nomf="/home/archives/$1"  #fichier d'archive dans lequel on travaille
racine="$(sed -n 3p $nomf | cut -d' ' -f2 | sed 's/.$//g')" #racine de l'archive dont on va remplacer le dernier char '\'
repa=$(echo -E "$racine$2" | sed 's/Â£Â£Â£//g')
#echo arg2 vaut $2
#echo $repa 
racinecmd=$(echo $racine | sed 's/\\/:/g')


if [ "$3" == "cd" ]; then #commande cd

i=1
trouve=0
reptrouve=0

headf=$( head -1 $nomf | cut -d':' -f2) #fin du header


repacd=$(echo "$4" | sed 's/\\/:/g' )

if [ $(echo $repacd | grep -c ':') -eq 1 ]; then

        repacd=$(echo -E "$4" |  sed "s/Â£Â£Â£/"$racinecmd"/g" | sed 's/:/\\/g') 

while [ $i -lt $headf ] #Tant que la ligne est inferieure Ã  la ligne de fin du header
do

        ligne=$(sed -n "$i"p $nomf) #ligne prend la valeur du contenu de la ligne i
       # echo "ligne vaut $ligne"
       # echo "directory $repa"



       if [[ "$(echo $ligne | sed 's/\\$//g')" == "directory $repacd" ]]; then #si la ligne Ã©valuÃ©e correspond au repertoire repa
                 
                 trouve=2
       
                fi



        i=$((i+1))

done     


else

while [ $i -lt $headf ] #Tant que la ligne est inferieure Ã  la ligne de fin du header
do

        ligne=$(sed -n "$i"p $nomf) #ligne prend la valeur du contenu de la ligne i
       # echo "ligne vaut $ligne"
       # echo "directory $repa"



       if [[ "$(echo $ligne | sed 's/\\$//g')" == "directory $repa" ]]; then #si la ligne Ã©valuÃ©e correspond au repertoire repa
                 fichstart=$i #on enregistre la ligne de debut du repertoire dans le header
                 #echo "fichstart vaut $fichstart"
                 reptrouve=1
       
                fi



        i=$((i+1))

done                                                    #permet de trouver la ligne de commencement du repertoire actuel dans le header pour pouvoir ensuite verifier si le fichier quon veut cat est bien dans le repertoire actuel (si ce n'est pas le chemin absolu ?"




if [ $reptrouve = 1 ]; then


j=$((fichstart+1)) # on enregistre dans j la ligne du premier reprtoire ou fichier correpondant au repertoire repa

while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ] #tant que la ligne n'est pas Ã©gale Ã  la fin du repertoire @, on Ã©value chaque ligne
do

        if [ "$(sed -n "$j"p $nomf | cut -d' ' -f1)" == "$4" ] && [ $(sed -n "$j"p $nomf | wc -w) -eq 3 ]; then #Si le repertoire recherchÃ© correspond Ã  la ligne Ã©valuÃ©e, et que son nombre d'arguments est egal Ã  3

                ldossiercd=$j #enregistrement de la ligne du fichier recherchÃ© dans le header
                trouve=1 #indique que le fichier a Ã©tÃ© trouvÃ©
        fi

j=$((j+1))

done

fi

fi

if [ $trouve -eq 1 ]; then #Si le fichier a Ã©tÃ© trouvÃ© dans le repertoire actuel

        echo "1"

elif [ $trouve -eq 2 ]; then

        echo "2"

else
        echo "0"

fi
trouve=0
reptrouve=0



elif [ "$3" == "ls" ]; then #commande ls 

i=1
trouve=0
trouvexe=0
headf=$( head -1 $nomf | cut -d':' -f2) #fin du header



while [ $i -lt $headf ] #Tant que la ligne est inferieure Ã  la ligne de fin du header
do

        ligne=$(sed -n "$i"p $nomf) #ligne prend la valeur du contenu de la ligne i
        #echo "ligne vaut $ligne"
       # echo "directory $repa"

        if [[ "$(echo $ligne | sed 's/\\$//g')" == "directory $repa" ]]; then #si la ligne Ã©valuÃ©e correspond au repertoire repa
        fichstart=$i #on enregistre la ligne de debut du repertoire dans le header
       #echo "fichstart vaut $fichstart"
        fi
        i=$((i+1))

done                                                    #permet de trouver la ligne de commencement du repertoire actuel dans le header pour pouvoir ensuite verifier si le fichier quon veut cat est bien dans le repertoire actuel (si ce n'est pas le chemin absolu ?"

j=$((fichstart+1)) # on enregistre dans j la ligne du premier reprtoire ou fichier correpondant au repertoire repa

if [ "$4" == "-l" ]; then #mode -l

        while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ] #tant que la ligne n'est pas Ã©gale Ã  la fin du repertoire @, on Ã©value chaque ligne
        do

                if [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ] && [ $(sed -n "$j"p $nomf | grep -c 'x') -eq 1 ]; then #verifie si fich est un exe

                        trouvexe=1
                     
                fi


                         if [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ] && [ $trouvexe -eq 1 ] && [[ "$(sed -n "$j"p $nomf)" =~ ^[^.] ]]; then 

                                 echo "$(sed -n "$j"p $nomf | sed 's/ /\* /' | cut -d' ' -f1,2,3 | awk '{print $2, $3, $1}')"  
                                 trouvexe=0

                         elif [[ "$(sed -n "$j"p $nomf)" =~ ^[^.] ]]; then 

                                echo "$(sed -n "$j"p $nomf | cut -d' ' -f1,2,3 | awk '{print $2, $3, $1}')"
                         fi

                        j=$((j+1))


        done


elif [ "$4" == "-a" ]; then 

   while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ] #tant que la ligne n'est pas Ã©gale Ã  la fin du repertoire @, on Ã©value chaque ligne
        do

       if [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ] && [ $(sed -n "$j"p $nomf | grep -c 'x') -eq 1 ]; then #verifie si fich est un exe

                        trouvexe=1
                     
                fi


                if [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ] && [ $trouvexe -eq 1 ]; then 
                        arg="$arg $(sed -n "$j"p $nomf | cut -d' ' -f1)*"
                        trouvexe=0

                elif [ $(sed -n "$j"p $nomf | wc -w) -eq 3 ]; then 

                        arg="$arg $(sed -n "$j"p $nomf | cut -d' ' -f1)\\ "

                else
                        arg="$arg $(sed -n "$j"p $nomf | cut -d' ' -f1)"
                fi

                        j=$((j+1))

                done 

                echo $arg
                arg=""



elif [ "$4" == "-al" ] || [ "$4" == "-la" ]; then

        while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ] #tant que la ligne n'est pas Ã©gale Ã  la fin du repertoire @, on Ã©value chaque ligne
        do

         if [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ] && [ $(sed -n "$j"p $nomf | grep -c 'x') -eq 1 ]; then #verifie si fich est un exe

                        trouvexe=1
                     
                fi

                         if [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ] && [ $trouvexe -eq 1 ]; then 

                                 echo "$(sed -n "$j"p $nomf | sed 's/ /\* /' | cut -d' ' -f1,2,3 | awk '{print $2, $3, $1}')" 
                                trouvexe=0 

                         else 
                                echo "$(sed -n "$j"p $nomf | cut -d' ' -f1,2,3 | awk '{print $2, $3, $1}')"
                         fi

                        j=$((j+1))

        done

else

        while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ] #tant que la ligne n'est pas Ã©gale Ã  la fin du repertoire @, on Ã©value chaque ligne
        do

              if [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ] && [ $(sed -n "$j"p $nomf | grep -c 'x') -eq 1 ]; then #verifie si fich est un exe

                        trouvexe=1
                     
                fi


                if [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ] && [ $trouvexe -eq 1 ] && [[ "$(sed -n "$j"p $nomf)" =~ ^[^.] ]]; then        
         
                        arg="$arg $(sed -n "$j"p $nomf | cut -d' ' -f1)*"
                        trouvexe=0

                elif [ $(sed -n "$j"p $nomf | wc -w) -eq 3 ]; then 

                        arg="$arg $(sed -n "$j"p $nomf | cut -d' ' -f1)\\ "

                elif [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ] && [[ "$(sed -n "$j"p $nomf)" =~ ^[^.] ]]; then

                        arg="$arg $(sed -n "$j"p $nomf | cut -d' ' -f1)"
                fi

                        j=$((j+1))


                done

                echo $arg
                arg=""

fi



elif [ "$3" == "mkdir" ]; then


exist=0
i=1
trouve=0

headf=$( head -1 $nomf | cut -d':' -f2) #fin du header



while [ $i -lt $headf ] #Tant que la ligne est inferieure Ã  la ligne de fin du header
do

        ligne=$(sed -n "$i"p $nomf) #ligne prend la valeur du contenu de la ligne i
       # echo "ligne vaut $ligne"
       # echo "directory $repa"

        if [[ "$(echo $ligne| sed 's/\\$//g')" == "directory $repa" ]]; then #si la ligne Ã©valuÃ©e correspond au repertoire repa
        fichstart=$i #on enregistre la ligne de debut du repertoire dans le header
#       echo "fichstart vaut $fichstart"
        fi
        i=$((i+1))

done                                                    #permet de trouver la ligne de commencement du repertoire actuel dans le header pour pouvoir ensuite verifier si le fichier quon veut cat est bien dans le repertoire actuel (si ce n'est pas le chemin absolu ?"

j=$((fichstart+1)) # on enregistre dans j la ligne du premier reprtoire ou fichier correpondant au repertoire repa







        while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ]  
        do
                if [ "$(sed -n "$j"p $nomf | cut -d' ' -f1)" == "$4" ]; then

                        exist=1
                        break
                fi
                j=$((j+1))
        done


if [ "$exist" == "1" ]; then

        echo "vsh: Le fichier ou dossier '$4' existe dÃ©jÃ  dans le rÃ©pertoire $(echo -E "$repa" | sed 's/\\/:/g' | sed "s/$racinecmd/\\\/g" | sed 's/:/\\/g' | sed 's/\\\\/\\/g')"

else

echo " " >> $nomf
nbr=1
j=$((fichstart+1))

        while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ]  
        do

                if [  $(printf '%d' "'$(sed -n "$j"p $nomf | cut -d' ' -f1 | cut -c"$nbr")") -lt $(printf '%d' "'$(echo -n "$4" | cut -c"$nbr")")  ]; then

                        j=$((j+1))
                        nbr=1


                elif [ $(printf '%d' "'$(sed -n "$j"p $nomf | cut -d' ' -f1 | cut -c"$nbr")") -gt $(printf '%d' "'$(echo -n "$4" | cut -c"$nbr")") ]; then
                      
                        break

                elif [  $(printf '%d' "'$(sed -n "$j"p $nomf | cut -d' ' -f1 | cut -c"$nbr")") -eq $(printf '%d' "'$(echo -n "$4" | cut -c"$nbr")") ]; then

                        nbr=$((nbr+1))

                fi

        done

        finrep=$j

        for (( i=$(wc -l $nomf | cut -d' ' -f1); i>=$finrep; i-- )); 
        do
                lignedessous=$(sed -n "$(($i-1))"p $nomf | sed 's/\\/\\\\/g')
                sed -i "${i}s/^.*$/$lignedessous/" $nomf
        done



sed -i "${finrep}s/^.*$/$4 drwxr-xr-x 4096/g" $nomf

trouvedoss=0


for ((i=$finrep; i>=$(($fichstart+1)); i--)); 
do
        if [ $(sed -n "$i"p $nomf | wc -w | cut -d' ' -f1) -eq 3 ] && [ $i -ne $finrep ]; then

                trouvedoss=$i
                break
        fi
done

if [ $trouvedoss -eq 0 ]; then

        nouvrep="$repa\\$4"
        k=$finrep
        echo " " >> $nomf && echo " " >> $nomf


        while [ "$(echo $(sed -n "$k"p $nomf))" != "@" ]; 
        do
                k=$((k+1))
        done

        finrep2=$((k+1))

        for (( a=$(wc -l $nomf | cut -d' ' -f1); a>=$finrep2; a-- )); 
        do
                lignedessous=$(sed -n "$(($a-2))"p $nomf | sed 's/\\/\\\\/g')
                sed -i "${a}s/^.*$/$lignedessous/" $nomf
        done

        repsed="$(echo -E $repa | sed 's/\\/:/g'):$4"


        sed -i "${finrep2}s/^.*$/directory $repsed/g" $nomf
        sed -i "${finrep2}s/:/\\\/g" $nomf
        finrep2=$((finrep2+1))
        sed -i "${finrep2}s/^.*$/\@/g" $nomf



else
        repav="$(echo -E $repa)\\$(sed -n "$trouvedoss"p $nomf | cut -d' ' -f1)"
        for ((b=$finrep; b<$headf; b++));
        do
                if [ "$(sed -n "$b"p $nomf | cut -d' ' -f2)" == "$(echo -E $repav)" ]; then

                        c=$b
                        while [ "$(echo $(sed -n "$c"p $nomf))" != '@' ];
                        do
                                c=$((c+1))
                        done

                        break
                fi



        done


        finrep2=$((c+1))

        for (( d=$(wc -l $nomf | cut -d' ' -f1); d>=$finrep2; d-- )); 
        do
                lignedessous=$(sed -n "$(($d-2))"p $nomf | sed 's/\\/\\\\/g')
                sed -i "${d}s/^.*$/$lignedessous/" $nomf
        done

        repsed="$(echo -E $repa | sed 's/\\/:/g'):$4"


        sed -i "${finrep2}s/^.*$/directory $repsed/g" $nomf
        sed -i "${finrep2}s/:/\\\/g" $nomf
        finrep2=$((finrep2+1))
        sed -i "${finrep2}s/^.*$/\@/g" $nomf



fi



sed -i "1s/^.*$/3:$(($headf+3))/g" $nomf

fi




elif [ "$3" == "cat" ]; then 

i=1
trouve=0

headf=$( head -1 $nomf | cut -d':' -f2) #fin du header



while [ $i -lt $headf ] #Tant que la ligne est inferieure Ã  la ligne de fin du header
do

        ligne=$(sed -n "$i"p $nomf) #ligne prend la valeur du contenu de la ligne i
        #echo "ligne vaut $ligne"
        #echo "directory $repa"

        if [[ "$(echo $ligne| sed 's/\\$//g')" == "directory $repa" ]]; then #si la ligne Ã©valuÃ©e correspond au repertoire repa
        fichstart=$i #on enregistre la ligne de debut du repertoire dans le header
#       echo "fichstart vaut $fichstart"
        fi
        i=$((i+1))

done                                                    #permet de trouver la ligne de commencement du repertoire actuel dans le header pour pouvoir ensuite verifier si le fichier quon veut cat est bien dans le repertoire actuel (si ce n'est pas le chemin absolu ?"

j=$((fichstart+1)) # on enregistre dans j la ligne du premier reprtoire ou fichier correpondant au repertoire repa

if [ $# -eq 4 ]; then # si il n'y  aqu'un seul fichier Ã  ouvrir (arg Ã  changer)

        while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ] #tant que la ligne n'est pas Ã©gale Ã  la fin du repertoire @, on Ã©value chaque ligne
        do

                if [ "$(sed -n "$j"p $nomf | cut -d' ' -f1)" == "$4" ] && [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ]; then #Si le fichier recherchÃ© correspond Ã  la ligne Ã©valuÃ©e, et que son nombre d'arguments est egal Ã  5

                lfichiercat=$j #enregistrement de la ligne du fichier recherchÃ© dans le header
                trouve=1 #indique que le fichier a Ã©tÃ© trouvÃ©
                fi

        j=$((j+1))

        done

        if [ $trouve -eq 1 ]; then #Si le fichier a Ã©tÃ© trouvÃ© dans le repertoire actuel

               # echo "La ligne $lfichiercat contient le fichier recherchÃ© $2 dans $repa"

                debfich=$(($(sed -n "$lfichiercat"p $nomf | cut -d' ' -f4) + $headf)) #ligne de debut du fichier
                longfich=$(sed -n "$lfichiercat"p $nomf | cut -d' ' -f5) #longueur du dÃ©but de fichier

                tail +$(($debfich - 1)) $nomf | head -$longfich

               # echo "Le fichier commence Ã  la ligne $debfich et prend $longfich lignes"



        else
                echo "Le fichier '$4' n'existe pas dans le rÃ©pertoire $(echo -E "$repa" | sed 's/\\/:/g' | sed "s/$racinecmd/\\\/g" | sed 's/:/\\/g' | sed 's/\\\\/\\/g')"
        fi
        trouve=0

elif [ $# -eq 5 ]; then  #si il y a deux fichiers Ã  cat

        while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ] #tant que la ligne n'est pas Ã©gale Ã  la fin du repertoire @, on Ã©value chaque ligne
        do

                if [ "$(sed -n "$j"p $nomf | cut -d' ' -f1)" == "$4" ] && [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ]; then #Si le fichier recherchÃ© correspond Ã  la ligne Ã©valuÃ©e, et que son nombre d'arguments est egal Ã  5

                lfichiercat=$j #enregistrement de la ligne du fichier recherchÃ© dans le header
                trouve=1 #indique que le fichier a Ã©tÃ© trouvÃ©
                fi

        j=$((j+1))

        done

        if [ $trouve -eq 1 ]; then #Si le fichier a Ã©tÃ© trouvÃ© dans le repertoire actuel

                #echo "La ligne $lfichiercat contient le fichier recherchÃ© $2 dans $repa"

                debfich=$(($(sed -n "$lfichiercat"p $nomf | cut -d' ' -f4) + $headf)) #ligne de debut du fichier
                longfich=$(sed -n "$lfichiercat"p $nomf | cut -d' ' -f5) #longueur du dÃ©but de fichier

                tail +$(($debfich - 1)) $nomf | head -$longfich

                #echo "Le fichier commence Ã  la ligne $debfich et prend $longfich lignes"



        else
                echo "Le fichier '$4' n'existe pas dans le rÃ©pertoire $(echo -E "$repa" | sed 's/\\/:/g' | sed "s/$racinecmd/\\\/g" | sed 's/:/\\/g' | sed 's/\\\\/\\/g')"
        fi
        trouve=0
        j=$((fichstart+1))
       echo " " # transition entre deux fichiers


       while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ] #tant que la ligne n'est pas Ã©gale Ã  la fin du repertoire @, on Ã©value chaque ligne
        do

                if [ "$(sed -n "$j"p $nomf | cut -d' ' -f1)" == "$5" ] && [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ]; then #Si le fichier recherchÃ© correspond Ã  la ligne Ã©valuÃ©e, et que son nombre d'arguments est egal Ã  5

                        lfichiercat=$j #enregistrement de la ligne du fichier recherchÃ© dans le header
                        trouve=1 #indique que le fichier a Ã©tÃ© trouvÃ©
                fi

        j=$((j+1))

        done

        if [ $trouve -eq 1 ]; then #Si le fichier a Ã©tÃ© trouvÃ© dans le repertoire actuel

                #echo "La ligne $lfichiercat contient le fichier recherchÃ© $2 dans $repa"

                debfich=$(($(sed -n "$lfichiercat"p $nomf | cut -d' ' -f4) + $headf)) #ligne de debut du fichier
                longfich=$(sed -n "$lfichiercat"p $nomf | cut -d' ' -f5) #longueur du dÃ©but de fichier

                tail +$(($debfich - 1)) $nomf | head -$longfich

        #echo "Le fichier commence Ã  la ligne $debfich et prend $longfich lignes"



        else
                echo "Le fichier '$5' n'existe pas dans le rÃ©pertoire $(echo -E "$repa" | sed 's/\\/:/g' | sed "s/$racinecmd/\\\/g" | sed 's/:/\\/g' | sed 's/\\\\/\\/g')"
        fi
        trouve=0

else
        echo "Arguments incorrects  pour la commande 'cat'"
fi

elif [ "$3" == "rm" ]; then #mode rm

i=1
trouve=0
trouved=0

headf=$( head -1 $nomf | cut -d':' -f2) #fin du header



while [ $i -lt $headf ] #Tant que la ligne est inferieure Ã  la ligne de fin du header
do

        ligne=$(sed -n "$i"p $nomf) #ligne prend la valeur du contenu de la ligne i
        #echo "ligne vaut $ligne"
        #echo "directory $repa"

        if [[ "$(echo $ligne | sed 's/\\$//g')" == "directory $repa" ]]; then #si la ligne Ã©valuÃ©e correspond au repertoire repa
        fichstart=$i #on enregistre la ligne de debut du repertoire dans le header
#       echo "fichstart vaut $fichstart"
        fi
        i=$((i+1))

done                                                    #permet de trouver la ligne de commencement du repertoire actuel dans le header pour pouvoir ensuite verifier si le fichier quon veut cat est bien dans le repertoire actuel (si ce n'est pas le chemin absolu ?"

j=$((fichstart+1)) # on enregistre dans j la ligne du premier reprtoire ou fichier correpondant au repertoire repa


while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ] #tant que la ligne n'est pas Ã©gale Ã  la fin du repertoire @, on Ã©value chaque ligne
        do

                if [ "$(sed -n "$j"p $nomf | cut -d' ' -f1)" == "$4" ] && [ $(sed -n "$j"p $nomf | wc -w) -eq 5 ]; then #Si le fichier recherchÃ© correspond Ã  la ligne Ã©valuÃ©e, et que son nombre d'arguments est egal Ã  5

                lfichiercat=$j #enregistrement de la ligne du fichier recherchÃ© dans le header
                trouve=1 #indique que le fichier a Ã©tÃ© trouvÃ©

                elif [ "$(sed -n "$j"p $nomf | cut -d' ' -f1)" == "$4" ] && [ $(sed -n "$j"p $nomf | wc -w) -eq 3 ]; then #SI le dossier recherchÃ© correspond Ã  la ligne Ã©valuÃ©e

                ldossier=$j
                trouved=1

                fi

        j=$((j+1))

        done

        if [ $trouve -eq 1 ]; then #Si le fichier a Ã©tÃ© trouvÃ© dans le repertoire actuel

                #echo "La ligne $lfichiercat contient le fichier recherchÃ© $2 dans $repa"

                debfich=$(($(sed -n "$lfichiercat"p $nomf | cut -d' ' -f4) + $(($headf-1)))) #ligne de debut du fichier
                longfich=$(sed -n "$lfichiercat"p $nomf | cut -d' ' -f5) #longueur du dÃ©but de fichier

                if [ $longfich -ne 0 ]; then #si le fichier ne comporte pas 0 lignes

                sudo sed -i "$debfich,$(($(($debfich+$longfich))-1))"d $nomf #supp lignes du fichier dans body

                fi 

                sudo sed -i "$lfichiercat"d $nomf                            #supp ligne du fichier dans header
                headf=$(($headf-1))                                  #actualise nbr de lignes du header
               sudo sed -i "1s/.*/3:$headf/g" $nomf                         #remplace ligne du header



                for ((k=$(($lfichiercat));k<=$(($headf-1));k++)); do #Ã  partir du fichier suppr dans le header, decrÃ©mentente toutes les lignes de commencement des fichiers suivants par le nombre de lignes du fichier del

                        if [ $(sed -n "$k"p $nomf | wc -w) -eq 5 ]; then

                                nvl1=$(($(sed -n "$k"p $nomf | cut -d' ' -f4)-$longfich))
                               sudo gawk -i inplace 'NR==nr1  {$4=nvl}1' "nr1=$k" "nvl=$nvl1" $nomf

                        fi
                done


        elif [ $trouved -eq 1 ]; then

               

sousdoss="$(sed -n "$fichstart"p $nomf | cut -d' ' -f2 | sed 's/\\$//g' | sed 's/$/\\/g')$4" #caractÃ¨res identifiant le sousdossier qui va etre suprimÃ©




  sudo sed -i "$ldossier"d $nomf                            #supp ligne du dossier dans header
                headf=$(($headf-1))                                  #actualise nbr de lignes du header
               sudo sed -i "1s/.*/3:$headf/g" $nomf                         #remplace ligne du header


l=$fichstart
while [ $l -lt $headf ];

                do
                        if [[ "$(sed -n "$l"p $nomf | cut -d' ' -f2)" =~ "$sousdoss" ]]; then #si le dossier est un sousdossier du dossier suppr



                                m=$(($l+1))

                                while [ "$(echo $(sed -n "$m"p $nomf))" != "@" ] # sort toutes les lignes des fichiers dans les sous dossiers
                                        do


########################## ETAPE 1 : on supprime les fichiers et leur contenu 

if [ $(sed -n "$m"p $nomf | wc -w) -eq 5 ]; then #si la ligne est un fichier

 debfich=$(($(sed -n "$m"p $nomf | cut -d' ' -f4) + $(($headf-1)))) #ligne de debut du fichier
                longfich=$(sed -n "$m"p $nomf | cut -d' ' -f5) #longueur du dÃ©but de fichier
                #echo longfich vaut $longfich
                #echo debfich vaut $debfich

                if [ $longfich -ne 0 ]; then #si le fichier ne comporte pas 0 lignes

                sudo sed -i "$debfich,$(($(($debfich+$longfich))-1))"d $nomf #supp lignes du fichier dans body

                fi 

                sudo sed -i "$m"d $nomf                 #supp ligne du fichier dans header
               headf=$(($headf-1))                                  #actualise nbr de lignes du header
              sudo sed -i "1s/.*/3:$headf/g" $nomf                         #remplace ligne du header



                for ((k=$(($m));k<=$(($headf-1));k++)); do #Ã  partir du fichier suppr dans le header, decrÃ©mentente toutes les lignes de commencement des fichiers suivants par le nombre de lignes du fichier del

                        if [ $(sed -n "$k"p $nomf | wc -w) -eq 5 ]; then

                                nvl1=$(($(sed -n "$k"p $nomf | cut -d' ' -f4)-$longfich))
                               sudo gawk -i inplace 'NR==nr1  {$4=nvl}1' "nr1=$k" "nvl=$nvl1" $nomf

                        fi
                done
                m=$((m-1)) #decremente m car il va Ãªtre recrÃ©mentÃ© aprÃ¨s, or il y a eu decalage de lignes dans le header

elif [ $(sed -n "$m"p $nomf | wc -w) -eq 3 ]; then #si la ligne est un dossier

                sudo sed -i "$m"d $nomf                 #supp ligne du dossier  dans header
               headf=$(($headf-1))                                  #actualise nbr de lignes du header
              sudo sed -i "1s/.*/3:$headf/g" $nomf                         #remplace ligne du header
                m=$((m-1)) #decremente m car il va Ãªtre recrÃ©mentÃ© aprÃ¨s, or il y a eu decalage de lignes dans le header
fi


        m=$((m+1))
done
fi
l=$((l+1))
done


l=$fichstart
while [ $l -lt $headf ]; #suppression des lignes de direcotry et des @

                do
                        if [[ "$(sed -n "$l"p $nomf | cut -d' ' -f2)" =~ "$sousdoss" ]]; then #si le dossier est un sousdossier du dossier suppr



                                sudo sed -i "$l,$((l+1))"d $nomf                #supp ligne du  directory et de l'arobase  dans header
               headf=$(($headf-2))                                  #actualise nbr de lignes du header
              sudo sed -i "1s/.*/3:$headf/g" $nomf                         #remplace ligne du header

                l=$((l-2)) #decremente de deux pour ligne @ et ligne directory


                        fi

                        l=$((l+1))
                done












        else
                echo "Le fichier ou dossier '$4' existe pas dans le rÃ©pertoire $(echo -E "$repa" | sed 's/\\/:/g' | sed "s/$racinecmd/\\\/g" | sed 's/:/\\/g' | sed 's/\\\\/\\/g')"
        fi
        trouve=0


elif [ "$3" == 'touch' ]; then

exist=0
i=1
trouve=0

headf=$( head -1 $nomf | cut -d':' -f2) #fin du header



while [ $i -lt $headf ] #Tant que la ligne est inferieure Ã  la ligne de fin du header
do

        ligne=$(sed -n "$i"p $nomf) #ligne prend la valeur du contenu de la ligne i
       # echo "ligne vaut $ligne"
       # echo "directory $repa"

        if [[ "$(echo $ligne| sed 's/\\$//g')" == "directory $repa" ]]; then #si la ligne Ã©valuÃ©e correspond au repertoire repa
        fichstart=$i #on enregistre la ligne de debut du repertoire dans le header
#       echo "fichstart vaut $fichstart"
        fi
        i=$((i+1))

done                                                    #permet de trouver la ligne de commencement du repertoire actuel dans le header pour pouvoir ensuite verifier si le fichier quon veut cat est bien dans le repertoire actuel (si ce n'est pas le chemin absolu ?"

j=$((fichstart+1)) # on enregistre dans j la ligne du premier reprtoire ou fichier correpondant au repertoire repa







        while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ]  
        do
                if [ "$(sed -n "$j"p $nomf | cut -d' ' -f1)" == "$4" ]; then

                        exist=1
                        break
                fi
                j=$((j+1))
        done


if [ "$exist" == "1" ]; then

        echo "vsh: Le fichier '$4' existe dÃ©jÃ  dans le rÃ©pertoire $(echo -E "$repa" | sed 's/\\/:/g' | sed "s/$racinecmd/\\\/g" | sed 's/:/\\/g' | sed 's/\\\\/\\/g')"


else

echo " " >> $nomf
nbr=1
j=$((fichstart+1))

        while [ "$(echo $(sed -n "$j"p $nomf))" != "@" ]  
        do
               # echo valeurligne vaut  $(printf '%d' "'$(sed -n "$j"p $nomf | cut -d' ' -f1 | cut -c"$nbr")") et valeurfich vaut $(printf '%d' "'$(echo -n "$4" | cut -c"$nbr")")         
                # echo j vaut $j

                if [  $(printf '%d' "'$(sed -n "$j"p $nomf | cut -d' ' -f1 | cut -c"$nbr")") -lt $(printf '%d' "'$(echo -n "$4" | cut -c"$nbr")")  ]; then

                        j=$((j+1))
                        nbr=1


                elif [ $(printf '%d' "'$(sed -n "$j"p $nomf | cut -d' ' -f1 | cut -c"$nbr")") -gt $(printf '%d' "'$(echo -n "$4" | cut -c"$nbr")") ]; then
                      
                        break

                elif [  $(printf '%d' "'$(sed -n "$j"p $nomf | cut -d' ' -f1 | cut -c"$nbr")") -eq $(printf '%d' "'$(echo -n "$4" | cut -c"$nbr")") ]; then

                        nbr=$((nbr+1))

                fi

        done

        finrep=$j
        #echo finrep vaut $finrep

        for (( i=$(wc -l $nomf | cut -d' ' -f1); i>=$finrep; i-- )); 
        do
                lignedessous=$(sed -n "$(($i-1))"p $nomf | sed 's/\\/\\\\/g')
                sed -i "${i}s/^.*$/$lignedessous/" $nomf
        done


debfich=1 

for ((n=$(($finrep-1)); n>=4 ; n--)); 
        do
                if [ $(sed -n "$n"p $nomf | wc -w | cut -d' ' -f1) -eq 5 ]; then

                fichav=$n
               debfichav=$(sed -n "$n"p $nomf | cut -d' ' -f4) #ligne de debut du fichier
               longfichav=$(sed -n "$n"p $nomf | cut -d' ' -f5) #longueur du dÃ©but de fichier
               debfich=$(($debfichav+$longfichav))
               break

                fi
        done

sed -i "${finrep}s/^.*$/$4 -rw-r--r-- 0 $debfich 0/g" $nomf
sed -i "1s/^.*$/3:$(($headf+1))/g" $nomf

fi



else
         echo "La commande '$3' n'est pas reconnue"
fi




fi


pkill -x nc > /dev/null 2>&1




}




# On accepte et traite les connexions

accept-loop
