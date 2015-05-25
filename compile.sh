

read -p "Voulez vous lancer l'application ? Appuyez sur entrée pour confirmer "

echo "
"
echo "----------------------------------------------------"
echo "             NETTOYAGE DES TABLES       "
echo "----------------------------------------------------"
echo "
"
/usr/local/pgsql/bin/psql base ouelaa -f drop.sql -q

echo "
"
echo "----------------------------------------------------"
echo "              NETTOYAGE EFFECTUÉE                "
echo "----------------------------------------------------"
echo "
"
read -p "Voulez vous créer les tables ? Appuyez sur entrée pour confirmer "

echo "
"
echo "----------------------------------------------------"
echo "            CREATION DE LA BASE                     "
echo "----------------------------------------------------"
echo "
"
/usr/local/pgsql/bin/psql base ouelaa -f creation.sql -q

echo "
"
echo "----------------------------------------------------"
echo "            CREATION EFFECTUÉE                      "
echo "----------------------------------------------------"
echo "
"
read -p "Voulez vous inserer les données ? Appuyez sur entrée pour confirmer "

/usr/local/pgsql/bin/psql base ouelaa -f insert.sql -q


echo "----------------------------------------------------"
echo "             INSERTION DES DONNÉES EFFECTUÉE        "
echo "----------------------------------------------------"

/usr/local/pgsql/bin/psql base ouelaa -f fun.sql -q
/usr/local/pgsql/bin/psql base ouelaa -f trigger.sql -q
echo "
echo "----------------------------------------------------""
echo " CREATION DES FONCTIONS ET DES TRIGGERS"
echo "----------------------------------------------------"


