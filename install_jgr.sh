#!/bin/bash
#
# Author: Iurie Malai
# http://r-interface.blogspot.com/
#
# This script is distributed under the GNU General Public License. The script
# is distributed without any warranty: I do not guarantee that the script will
# work in your system, and I will not be held responsible for any harm or damage
# caused by its use. Please make sure that you know what you are doing.
#
# If you reproduce this script for personal non-commercial use, you must refer to
# Iurie Malai as your source by referring to this web page:
# http://r-interface.blogspot.com/
#
# INSTRUCTIONS
# Copy and paste this script in a file, for example 'r-guis-installer', and save
# it in your home folder. Start the terminal and make sure you are in your home
# folder or in that folder where you saved the file 'r-guis-installer'. Make it
# executable with this command (in terminal): 'chmod +x r-guis-installer' (without
# quotes). Become root with command 'sudo su' or 'su' and run: ./r-guis-installer.
# The script will install R, JGR and Deducer with other additional packages.
# Start JGR from 'Applications>Science>Java GUI for R'. To autoload Deducer and
# DeducerExtras packages open 'Packages & Data > Package Manager' from JGR menu
# and select 'load' and 'default' next to Deducer and DeducerExtras.
#

shopt -s extglob

# Check for root privileges (required)
# ************************************

if [[ $EUID -ne 0 ]]; then
    echo "";
    echo "WARNING! You must have root privileges!" 2>&1;
    echo "Run in terminal 'sudo su' OR 'su', enter your password,";
    echo "then run this script again!";
    echo "";
    exit 1
else
    echo
fi

# Check OpenJDK versions in software repository
# *********************************************
OPENJDK=$(apt-cache search openjdk | grep openjdk | grep "\-jdk" | cut -d' ' -f1)
OPENJDK=( $OPENJDK )
JDKCOUNT=${#OPENJDK[@]}

function choose_cran() {
# ***********************
  INDEX=0;
  TMPDIR1=$(mktemp);

  wget http://cran.r-project.org/CRAN_mirrors.csv -P $TMPDIR1;

  while read LINE; do
    if [[ "$INDEX" -ge 1 ]]; then
      MIRRORS_NAME[$INDEX]=$(echo $INDEX". "${LINE//[\"]/} | cut -d, -f1);
      MIRRORS_URL[$INDEX]=$(echo ${LINE//[\"]/} | cut -d, -f4);
    fi
    INDEX=$(($INDEX+1));
  done < $TMPDIR1/CRAN_mirrors.csv;

  INDEX=$(($INDEX-1));
  echo "${MIRRORS_NAME[*]/%/$'\n'}" | column;

  ANSWER=0
  DEFAULT=5

  echo '';
  echo 'Choose a CRAN mirror near to your location (type the number)!';
  read -p 'Not choosing / Wrong typing is equivalent to default (CRAN): ' ANSWER;

  #shopt -s extglob
  if [[ $ANSWER == ?(-)+([0-9]) ]]
    then ANSWER=$((ANSWER));
    else ANSWER=$DEFAULT;
  fi

  if [ $ANSWER -lt 1 ] || [ $ANSWER -gt $INDEX ]
    then ANSWER=$DEFAULT;
  fi

  REPOS=${MIRRORS_URL[$ANSWER]};

  unset INDEX;
  unset TMPDIR;
  unset LINE;
  unset MIRRORS_NAME;
  unset MIRRORS_URL;
  unset ANSWER;
  unset DEFAULT;
  rm -r $TMPDIR1;
  #unset REPOS;

}

function cran_setup() {
# Add a required CRAN repository to the '/etc/apt/sources.list' file
# ******************************************************************
  echo '' >> $APTLIST
  if [[ $DISTRO == "debian" ]]; then
    echo 'deb '$REPOS'bin/linux/'$DISTRO' '$CODENAME'-cran/' >> $APTLIST
    gpg --keyserver subkeys.pgp.net --recv-key 381BA480
    gpg -a --export 381BA480 | apt-key add -
    #gpg -a --export 381BA480 > jranke_cran.asc
    #apt-key add jranke_cran.asc
    else
    echo 'deb '$REPOS'bin/linux/'$DISTRO' '$CODENAME'/' >> $APTLIST
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
    gpg -a --export E084DAB9 | apt-key add -
  fi
}

function install_code() {
# ************************
  apt-get update && apt-get -y upgrade && apt-get install -y r-base-dev r-recommended

  if [[ $JDKCOUNT == 1 ]]; then
    apt-get install -y ${OPENJDK[0]}
    update-java-alternatives -s java-6-openjdk # ???
    # ----------------------------------------------
    else
    echo ""
    echo "For your distro "$JDKCOUNT" versions of OpenJDK are available."
    echo "Choose what version you want to install:"

    for (( i=1; i<=JDKCOUNT; i++ )); do
      if [[ $i<$JDKCOUNT ]]; then
        echo $i") "${OPENJDK[$i-1]}
      else echo $i") "${OPENJDK[$i-1]}" (recommended)"
      fi
    done
    echo ""

    while [[ 1 ]] && ([[ $choice -lt 1 ]] || [[ $choice -gt $JDKCOUNT ]]); do
      read -p "Please make a selection, select q to quit: " choice
      case $choice in
        # Check for digits
      +([0-9]))
        if [[ $choice -lt 1 ]] || [[ $choice -gt $JDKCOUNT ]];
          then echo "Invalid choice"
          else
          apt-get install -y ${OPENJDK[$choice-1]}
          if [ `getconf LONG_BIT` = "64" ]; then
            update-java-alternatives -s java-1.7.0-openjdk-amd64 #???
            else update-java-alternatives -s java-1.7.0-openjdk-i386 #???
            # -----------------------------------------------------------
          fi
        fi
      ;;
       q|Q)
         break
         ;;
          *)
         echo "Invalid choice"
         ;;
      esac
    done
  fi

  R CMD javareconf

# Install JGR, Deducer and DeducerExtras packages in R.
  R --no-save <<RSCRIPT
    update.packages(ask=FALSE, repos = 'http://cran.r-project.org')
    install.packages(c('JGR', 'Deducer', 'DeducerExtras'), repos = "http://cran.r-project.org/")
    library('JGR')
    JGR(update = TRUE)
    JGR()
    warnings()
RSCRIPT

# Kill the opened JGR (that was needed to create the JGR launcher).
  sleep 3 && killall java

# Download an icon image for the JGR menu entry.
  wget https://sites.google.com/site/iuriemalai/graphical-user-interfaces-for-r/how-to-install-gnu-r-jgr-and-deducer-in-ubuntu/jgr-48x48.jpg --directory-prefix=/usr/share/icons/

# Create a menu entry for JGR in Applications > Science.
  echo "[Desktop Entry]" > /usr/share/applications/jgr.desktop
  echo "Type=Application" >> /usr/share/applications/jgr.desktop
  echo "Terminal=false" >> /usr/share/applications/jgr.desktop
  echo "Name=JGR - Java Gui for R" >> /usr/share/applications/jgr.desktop
  echo "Exec=/usr/local/lib/R/site-library/JGR/scripts/run" >> /usr/share/applications/jgr.desktop
  echo "Icon=/usr/share/icons/jgr-48x48.jpg" >> /usr/share/applications/jgr.desktop
  echo "Comment=Java Gui for R" >> /usr/share/applications/jgr.desktop
  echo "Categories=Science;Education;" >> /usr/share/applications/jgr.desktop
}

# Check if the distribution is based on Debian or Ubuntu repositories
# *******************************************************************
APTLIST='/etc/apt/sources.list'

while read LINE; do
  if [[ "$LINE" == *debian* ]]; then
    DISTRO="debian"
    CODENAME=$(echo $LINE | cut -d" " -f3)
    break
    else
    if [[ "$LINE" == *ubuntu* ]]; then
      DISTRO="ubuntu"
      CODENAME=$(echo $LINE | cut -d" " -f3)
      break
    fi
  fi
done < ${APTLIST}

if [[ "$DISTRO" != "debian" && "$DISTRO" != "ubuntu" ]]; then
  echo "Sorry! This distro is not based on Debian or Ubuntu repositories,"
  echo "so, we can't continue the installation!"
  exit 1
fi

SOURCES=0

# Search for and count CRAN repositories in the '/etc/apt/sources.list' file
# **************************************************************************
while read LINE; do
  if [[ "$LINE" == */bin/linux/$DISTRO* ]] # && [[ "$LINE" == *$CODENAME* ]]
    then let SOURCES++; fi
done < ${APTLIST}

if [[ "$SOURCES" == 0 ]]; then

  echo "You do not have setup yet a CRAN repository/mirror (required)!";
  PS3='Please, enter your choice: '
  options=("Setup automatically" "Choose manually from a list" "Quit")
  select opt in "${options[@]}"
  do
    case $opt in
      "Setup automatically")
        REPOS='http://cran.r-project.org/'
        cran_setup
        install_code
        ;;
      "Choose manually from a list")
        choose_cran
        cran_setup
        install_code
        ;;
      "Quit")
        break
        ;;
      *) echo invalid option;;
    esac
  done
fi

if [[ "$SOURCES" == 1 ]]; then
  install_code
fi

if [[ "$SOURCES" -gt 1 ]]; then
  echo 'WARNING! You have in your /etc/apt/sources.list file more than one CRAN';
  echo 'repositories! Delete the unnecessary records and leave only one for your';
  echo 'distro,or delete all of them and run this script again!';
  echo '';
  exit;
fi

exit 0
