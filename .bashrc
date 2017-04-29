# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions

DCMDICTPATH=/usr/local/share/dcmtk/dicom.dic:/usr/local/share/dcmtk/private.dic:/usr/local/share/dcmtk/diconde.dic:/home/smihajlovic/private.dic
KEYFILE="/home/smihajlovic/keys.txt"
JOBLOG="/home/smihajlovic/joblog.txt"
DCMENCHOME="/home/smihajlovic/dcmenc/"
export KEYFILE
export DCMDICTPATH
export JOBLOG
export DCMENCHOME
