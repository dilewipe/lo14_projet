#!/bin/bash




if [ $# -eq 0 ]; then

        echo -e "vsh: Options pour la commande manquantes\n" #verifie que le nombre d'arguments est supÃ©rieur Ã  0

else


        if [ "$1" == "-list" ]; then

                if [ $# -ne 3 ] || ! [[ "$2" == "localhost" || "$2" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || ! [[ "$3" =~ ^(1000|[0-9]{1,3})$ ]]; then #Verif si bon nombre d'arg, bon nom de serveur, bon numero de port

                         echo -e "vsh: Options pour la commande manquantes\nvsh: Options pour l'argument '-list': [nom_serveur] [port]"

                 else 
                         echo "list" | nc $2 $3 #connexion serveur et envoie commande list
                fi


        elif [ "$1" == '-browse' ]; then

                if [ $# -ne 4 ] || ! [[ "$2" == "localhost" || "$2" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || ! [[ "$3" =~ ^(1000|[0-9]{1,3})$ ]]; then #Verif si bon nombre d'arg, bon nom de serveur, bon numero de port

                         echo -e "vsh: Options pour la commande manquantes\nvsh: Options pour l'argument '-browse': [nom_serveur] [port] [nom_archive]"

                 else
                         server=$2
                         port=$3
                         archive=$4
                        repa="Â£Â£Â£"


                        while true
                        do

                                repaserveur=$(sed 's/\\/\\\\/g' <<< "$repa")

                                read -r -p "[$(echo $repa | sed 's/Â£Â£Â£/\\/g' | sed 's/\\\\/\\/g')]-vsh> " action
                                set -- $action


                                if [ "$1" == 'exit' ]; then

                                        break

                                elif [ "$1" == 'cd' ]; then

                                        if [ $# != 2 ]; then

                                                        echo "vsh: Arguments pour la commande 'pwd' incorrects"
                                                        echo " "
                                                else


                                        if [ "$2" == '..' ]; then
                                               
                                                if [ "$repa" != 'Â£Â£Â£' ]; then

                                                cutnum=$(grep -o '\\' <<< "$repa" | grep -c '\\')
                                                repa=$(echo $repa | cut --complement -d'\' -f$(($cutnum+1)))

                                                fi

                                        elif [ "$2" == '\' ]; then

                                                repa="Â£Â£Â£"

                                        else

                                                if [ $(echo $2 | sed 's/\\/:/g' | grep -c ':') -eq 1 ]; then

                                                repacd=$(echo $2 | sed 's/^/Â£Â£Â£/g' | sed 's/\\/\\\\/g')
                                                trouve="$(echo "browse $archive $repaserveur $1 $repacd" | nc $server $port)"
                                                else

                                                trouve="$(echo "browse $archive $repaserveur $1 $2" | nc $server $port)"
                                                fi


                                                if [ "$trouve" == "0" ]; then

                                                        if [ "$repa" != 'Â£Â£Â£' ]; then

                                                        echo "Le sous-rÃ©pertoire '$2' n'existe pas dans le rÃ©pertoire $(echo $repa | sed 's/Â£Â£Â£//g')" 
                                                echo " "
                                                else 

                                                        echo "Le sous-rÃ©pertoire '$2' n'existe pas dans le rÃ©pertoire \\" 
                                                        echo " "
                                                        fi



                                                 elif [ "$trouve" == "1" ]; then 

                                                         repa="$repa\\$2"

                                                 elif [ "$trouve" == "2" ]; then

                                                         repa="$(echo $repacd | sed 's/\\\\/\\/g')"
                                                fi


                                        fi

                                        fi



                                elif [ "$1" == 'pwd' ]; then

                                        if [ $# -gt 1 ]; then 

                                                echo "vsh: Arguments pour la commande 'pwd' incorrects"
                                                        echo " "
                                        else

                                        if [ "$repa" != 'Â£Â£Â£' ]; then

                                                echo -E "$repa" | sed 's/Â£Â£Â£//g'

                                        else
                                                echo -E "$repa" | sed 's/Â£Â£Â£/\\/g'
                                        fi
                                                echo " "
                                        fi


                                elif [ "$1" = 'cat' ]; then

                                                if [ $# -gt 3 ] || [ $# -lt 2 ]; then

                                                        echo "vsh: Arguments pour la commande 'pwd' incorrects"
                                                        echo " "
                                                else

                                                        if [ $(echo $2 | sed 's/\\/:/g' | grep -c ':') -eq 1 ] && [ $# -eq 2 ]; then 
                                cutnumabs=$(echo $2 | sed 's/\\/:/g' | grep -o ':' | grep -c ':')
                                repabs=$(echo $2 | cut --complement -d'\' -f$(($cutnumabs+1)) | sed 's/^/Â£Â£Â£/g' | sed 's/\\/\\\\/g')
                                cible=$(echo $2 | cut -d'\' -f$(($cutnumabs+1)))

                                        echo "browse $archive $repabs $1 $cible" | nc $server $port



                                        else


                                        #echo "$repaserveur"
                                        echo "browse $archive $repaserveur $1 $2 $3" | nc $server $port

                                                        fi


                                                fi


                                elif [ "$1" == 'ls' ]; then

                                                if [ "$2" != '' ] && [ "$2" != '-a' ] && [ "$2" != '-l' ] && [ "$2" != '-al' ] && [ "$2" != '-la' ]; then
                                                        echo "vsh: Arguments pour la commande 'ls' incorrects"
                                                        echo " "
                                                else

                                                #echo "$repaserveur"
                                                echo "browse $archive $repaserveur $1 $2" | nc $server $port

                                                fi

                                elif [ "$1" == 'rm' ]; then

                                        if [ $# != 2 ]; then

                                                        echo "vsh: Arguments pour la commande 'rm' incorrects"
                                                else

                                                        if [ $(echo $2 | sed 's/\\/:/g' | grep -c ':') -eq 1 ]; then

                                cutnumabs=$(echo $2 | sed 's/\\/:/g' | grep -o ':' | grep -c ':')
                                repabs=$(echo $2 | cut --complement -d'\' -f$(($cutnumabs+1)) | sed 's/^/Â£Â£Â£/g' | sed 's/\\/\\\\/g')
                                cible=$(echo $2 | cut -d'\' -f$(($cutnumabs+1)))

                                        echo "browse $archive $repabs $1 $cible $3" | nc $server $port

                                                        else

                                                #echo "$repaserveur"
                                                echo "browse $archive $repaserveur $1 $2" | nc $server $port

                                                        fi
                                        fi


                                elif [ "$1" == 'touch' ]; then

                                        if [ $# != 2 ]; then

                                                        echo "vsh: Arguments pour la commande 'touch' incorrects"
                                                else

                                                if [ $(echo $2 | sed 's/\\/:/g' | grep -c ':') -eq 1 ]; then

                                cutnumabs=$(echo $2 | sed 's/\\/:/g' | grep -o ':' | grep -c ':')
                                repabs=$(echo $2 | cut --complement -d'\' -f$(($cutnumabs+1)) | sed 's/^/Â£Â£Â£/g' | sed 's/\\/\\\\/g')
                                cible=$(echo $2 | cut -d'\' -f$(($cutnumabs+1)))

                                        echo "browse $archive $repabs $1 $cible $3" | nc $server $port

                                                else

                                        echo "browse $archive $repaserveur $1 $2" | nc $server $port

                                                fi


                                        fi



                                elif [ "$1" == 'mkdir' ]; then

                                        if [ $# != 2 ]; then

                                                        echo "vsh: Arguments pour la commande 'mkdir' incorrects"
                                                else

                                if [ $(echo $2 | sed 's/\\/:/g' | grep -c ':') -eq 1 ]; then

                                cutnumabs=$(echo $2 | sed 's/\\/:/g' | grep -o ':' | grep -c ':')
                                repabs=$(echo $2 | cut --complement -d'\' -f$(($cutnumabs+1)) | sed 's/^/Â£Â£Â£/g' | sed 's/\\/\\\\/g')
                                cible=$(echo $2 | cut -d'\' -f$(($cutnumabs+1)))

                                        echo "browse $archive $repabs $1 $cible $3" | nc $server $port
                                else

                                                echo "browse $archive $repaserveur $1 $2" | nc $server $port
                                fi
                                        fi



                                else
                                        echo "vsh: La commande '$1' n'est pas reconnue"
                                        echo " "


                                fi
                        done
                fi




        elif [ "$1" == '-create' ]; then

        if [ $# -ne 4 ] || ! [[ "$2" == "localhost" || "$2" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || ! [[ "$3" =~ ^(1000|[0-9]{1,3})$ ]]; then #Verif si bon nombre d'arg, bon nom de serveur, bon numero de port

                         echo -e "vsh: Options pour la commande manquantes\nvsh: Options pour l'argument '-create': [nom_serveur] [port] [nom_archive]"

                 else



touch /tmp/$4 #CrÃ©er le fichier qui contiendra l'archive
chmod +w /tmp/$4

dir=$(find . -type d)

for i in $dir
do
        ligne=$(($(ls -al $i | tail +4 | wc -l)+2))   #Compte le nombre de lignes pour chaque rÃ©pertoire + ligne @ et ligne directory
        headtot=$(($headtot + $ligne))
done

headtot=$(($headtot+3))  #Rajoute les lignes du dÃ©but et de la fin 

echo "3:$headtot">> /tmp/$4
echo " ">> /tmp/$4
bstart=$(($headtot+1))
repa=$(pwd | awk -F/ '{print $NF}') #Repertoire dans lequel l'utilisateur effectue la commande 


for i in $dir  
do
        echo "directory $i" | sed "s@\.@$PWD@g" | sed 's/\//\\/g' | sed 's/directory \\/directory /g'>> /tmp/$4 #Renvoie nom du repertoire avec structure modifiÃ©e

        if [ $(ls -al $i | tail +4 | wc -l) -gt 0 ]; then #Verifie si ya qqch dans le ls 

                for l in $(ls $i -a | tail +3) #ItÃ¨re dans chaque ligne du ls
                do
                        wc -l  $i/$l &> /dev/null
                        RESULT=$?                       #Verifie si la ligne est un fichier 
                        if [ $RESULT -eq 0 ]; then 

                                longueur=$(wc -l $i/$l | cut -d' ' -f1)  #Compte le nombre de lignes du fichier

                                echo "$(ls -ld $i/$l | sed 's/  */ /g' | cut -d' ' -f1,5,9 | awk '{print $3,$1,$2}' | sed 's/^[.\/].*\///g') $(($bstart-$headtot)) $longueur">> /tmp/$4
                                bstart=$(($bstart+$longueur))
                        else

                                echo "$(ls -ld $i/$l | sed 's/   */ /g' | cut -d' ' -f1,5,9 | awk '{print $3,$1,$2}' | sed 's/^[.\/].*\///g')">> /tmp/$4
                        fi
                done


        fi
       echo "@">> /tmp/$4
done

n=1

for i in $dir       #Affiche le contenu des fichiers par repertoire et par ordre alphabetique
do
        for j in $(find $i -maxdepth 1 -type f | sort) 
        do
                fichlong=$(wc -l $j | cut -d' ' -f1)
                q=1
                while [ $q -le $fichlong ]; 
                do
                          sed -n "$q"p $j>> /tmp/$4
                          q=$((q+1))
                 done
         done


done

sudo sed -i '3s/$/\\/g' /tmp/$4
#sudo mv /tmp/$4 $PWD


archive=/tmp/$4
p=1
fin=$(wc -l $archive | cut -d' ' -f1)

while [ $p -le $fin ]; 
do
 sed -i "${p}s/$/%%/g" $archive
 sed -i "${p}s/\\\/Â£Â£/g" $archive

 p=$((p+1))
done


echo -E create $4 $(cat $archive) | nc $2 $3
sudo rm $archive

                fi


        elif [ "$1" == '-extract' ]; then

                if [ $# -ne 4 ] || ! [[ "$2" == "localhost" || "$2" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || ! [[ "$3" =~ ^(1000|[0-9]{1,3})$ ]]; then #Verif si bon nombre d'arg, bon nom de serveur, bon numero de port 
                                 
                        echo -e "vsh: Options pour la commande manquantes\nvsh: Options pour l'argument '-browse': [nom_serveur] [port] [nom_archive]"

                 else
                         echo extract $4 | nc $2 $3 > $4

if [ "$(sed -n 1p $4)" == "$(echo "vsh: Le fichier '$4' est introuvable")" ]; then

        sed -n 1p $4
        sudo rm $4

else

                         #MODE EXTRACT 
nomf=$4

# On rÃ©cupÃ¨re le headstart et le bodystart
hdstart=$( head -1 $nomf | cut -d: -f1 )
bdstart=$( head -1 $nomf | cut -d: -f2 )

l=$hdstart      # l stockera le numÃ©ro de la ligne en cours de traitement

root=$(sed -n "$hdstart"p $nomf | cut -d' ' -f2 | sed 's/\\/\//g')      # On stocke la racine de l'archive

# echo $root

#dir=$(wc -l $nomf | cut -d' ' -f1)
#n=$bdstart
#while [ $n -le $dir ]
#do
#       sed -i "$n"'s/\\/\\\\/g' $nomf
#       ((n++))
#done

num=0

while [ $l -lt $bdstart ]       # Tant que la ligne analysÃ©e fait encore partie du header
do
        line=$(sed -n "$l"p $nomf)              # line stocke le contenu de la ligne l

        # Si c'est Ã©crit directory en dÃ©but de ligne et que c'est pas le nom du fichier
        if [ $(echo $line | cut -d' ' -f1) = directory -a $(echo $line | wc -w) -eq 2 ]; then
                path=$(echo $line | cut -d' ' -f2 | sed 's/\\/\//g' | sed "s~$root~~g") # On enregistre le rÃ©pertoire courant
#               echo $path
                if [ \! -d $path ]; then                # Si le rÃ©pertoire n'existe pas, on le crÃ©e

                        mkdir $path
                fi
                ((num++))
        fi

        if [ $(echo $line | wc -w) -eq 3 ]; then        # Si 3 Ã©lÃ©ments dans la ligne, alors c'est un rÃ©pertoire, et on le crÃ©e

                nom_rep=$(echo $line | cut -d' ' -f1)

                if [ $num -eq 1 ]; then
                        mkdir $nom_rep
                else
                        mkdir "$path/$nom_rep"
                fi

                proprio=$(echo $line | cut -d' ' -f2 | cut -c2,3,4 | sed 's/-//g')
                group=$(echo $line | cut -d' ' -f2 | cut -c5,6,7 | sed 's/-//g')
                others=$(echo $line | cut -d' ' -f2 | cut -c8,9,10 | sed 's/-//g')

                if [ $num -eq 1 ]; then
                        chmod -f u=$proprio,g=$group,o=$others $nom_rep
                else
                        chmod -f u=$proprio,g=$group,o=$others $path/$nom_rep
                fi

        fi

        if [ $(echo $line | wc -w) -eq 5 ]; then        # Si 5 Ã©lÃ©ments dans la ligne, alors c'est un fichier
                start=$(($(echo $line | cut -d' ' -f4)-2+$bdstart))             # On rÃ©cupÃ¨re la ligne du dÃ©but du contenu du fichier
                duration=$(echo $line | cut -d' ' -f5)          # On rÃ©cupÃ¨re le nombre de lignes du contenu du fichier
                nb_line=1
                nom_fichier=$(echo $line | cut -d' ' -f1)

                if [ $num -eq 1 ]; then         # On crÃ©e le fichier vide pour pouvoir le remplir aprÃ¨s
                        touch $nom_fichier
                else
                        touch "$path/$nom_fichier"
                fi

                for ((d=$start; d<=$(($start+$duration)); d++));
                do
                        sed -i "${d}s/\\\/:backslash:/g" $nomf
                done


                while read ligne
                do
                        if [ $nb_line -ge $start -a $nb_line -lt $(($start+$duration)) ]; then          # Si la ligne parcourue est une ligne que contient le fichier

                                if [ $num -eq 1 ]; then          # On ajoute la ligne dans le fichier
                                        echo $ligne | sed 's/:backslash:/\\/g' >> $nom_fichier
                                else
                                        echo $ligne | sed 's/:backslash:/\\/g' >> "$path/$nom_fichier"
                                fi
                        fi
                        ((nb_line++))
                done < $nomf

                proprio=$(echo $line | cut -d' ' -f2 | cut -c2,3,4 | sed 's/-//g')
                group=$(echo $line | cut -d' ' -f2 | cut -c5,6,7 | sed 's/-//g')
                others=$(echo $line | cut -d' ' -f2 | cut -c8,9,10 | sed 's/-//g')

                if [ $num -eq 1 ]; then
                        chmod -f u=$proprio,g=$group,o=$others $nom_fichier
                else
                        chmod -f u=$proprio,g=$group,o=$others $path/$nom_fichier
                fi

        fi

        ((l++))         # on itÃ¨re le numÃ©ro de ligne pour passer Ã  la ligne suivante
done < $nomf

sudo rm $nomf


                         #FIN MODE EXTRACT

fi
                fi


        else 
                echo "vsh: Option pour la commande non reconnue"
        fi




fi
