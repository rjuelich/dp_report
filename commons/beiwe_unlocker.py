#!/usr/bin/env python

import os
import beiwe
import getpass as gp
import sys
import getopt
import pexpect
import argparse
import csv

#def main(argv):
#	rawpath = ''
#	try:
 #     		opts, args = getopt.getopt(argv,"p",["rpath="])
#	except getopt.GetoptError:
#		print 'unlockerV2.py -p <rawpath>'
#		sys.exit(2)
#	for opt, arg in opts:
#		if opt in ("-p"):
#			rawpath = arg
	


#if __name__ == "__main__":
#	main(sys.argv[1:])
#rawpath = str(sys.argv[2])


## --- parse command line arguments
parser = argparse.ArgumentParser(description="Beiwe unlocker")
parser.add_argument("-p", "--rawpath", required=True, help="Path to raw data")
parser.add_argument("-s", "--study", required=True, help="study name")

args = parser.parse_args(sys.argv[1:])
rawpath = args.rawpath
study = args.study
user = gp.getuser()

def main():
    # path to locked files
    #base = "/ncf/beiwe/beiwe-data"
    #study = "McLean_Baker_and_Buckner_Circuit_Dynamics_in_Bipolar_Disorder"
    #patient = "949iuit"
    #datatype = "gps"
    #data_dir = os.path.join(base, study, patient, datatype)

    # read passphrase
    #passphrase = gp.getpass("enter passphrase: ")
    #passphrase=open('/users/rjj/.' + study + '_auth','r').read().rstrip()
    passphrase=open('/users/' + user +'/.' + study + '_auth','r').read().rstrip()
    #passphrase="addle shindy winded subnormal"
    key = None
    for f in os.listdir(rawpath):          # iterate over files
	fstr = str(f)
	fstr = fstr.replace(".lock","")
	fstr= fstr.replace(" ","_")
        fullfile = os.path.join(rawpath, f)
        if os.path.isdir(fullfile):         # skip sub-directories
            continue
        with open(fullfile, "rb") as fp:    # open file for reading
            if not key:                     # get key (once per study)
                key = beiwe.key_from_file(fp, passphrase)
            data = beiwe.unlock(fp, key)    # unlock file content
	    file = open(fstr, "wb")
	    file.write(data)
	    file.close()
#        process(data)                       # process file content
#        raw_input("press enter to proceed")

#def process(data):
#    pass

if __name__ == "__main__":
    main()
#exit()

