import os
import subprocess
import glob
from typing import List, Union

class fmri_tools:

    """
    2023-07-18 : init
        - can generate list of subject IDs from a directory of subject folders (default), a subject list text file, or an origin directory with subject session folders
        - need to make cp_and_rename_files() more generalizable

    """

    def __init__(self, studydir: str, origin_sessions_dir: Union[str, None] = None, subjectlist_text: Union[str, None] = None):
        self.studydir = studydir
        if subjectlist_text is not None:
            self.read_sublist_txt(subjectlist_text)
        elif origin_sessions_dir is not None:
            self.get_sublist_from_session_dirs(origin_sessions_dir)
        else:
            self.get_sublist(studydir)

    # Run commands in system terminal
    def exec_cmds(self, commands):
        for command in commands:
            subprocess.run(command, shell=True, executable='/bin/bash') # run command in bash shell
    
    # Get subject list from subject folder names
    def get_sublist(self, studydir: str):
        subdirs = glob.glob(f'{studydir}/*')
        subs = []
        for s in subdirs:
            subID = s.split('/')
            sub = subID[-1]
            subs.append(sub)
            print(sub)
        print(f'{len(subs)} subjects.')
        self.subs = subs

    # Get list of subject IDs and sessions from origin dir organized by sessions (ex. 97021_1, 97021_2, 97022_1, 97022_2, etc.)
    def get_sublist_from_session_dirs(self, origin):
        sessiondirs = glob.glob(f'{origin}/*')
        sessionlist = []
        for s in sessiondirs:
            sessiondir_ls = s.split('/')
            sub = sessiondir_ls[-1]
            print(sub)
            sessionlist.append(sub)
        sublist = []
        for s in sessionlist:
            sub = s
            if sub[-1] == '1':
                sub = sub[:-2]
                if (sub in sublist) == False:
                    sublist.append(sub)
            elif sub[-1] == '2':
                sub = sub[:-2]
                if (sub in sublist) == False:
                    sublist.append(sub)
        for sub in sublist:
            print(sub)
        print(f'{len(sublist)} subjects.')
        self.subs = sublist

    # Read subject list from a text file
    def read_sublist_txt(self, subjlist):
        s = open(subjlist,'r')
        subjs = s.readlines()
        s.close()
        subjs = [el.strip('\n') for el in subjs]
        subjs = [el.strip(' ') for el in subjs]
        for sub in subjs:
            print(sub)
        print(f'{len(subjs)} subjects.')
        self.subs = subjs

    # Read temporary subject list from a text file (doesn't change self.subs object)
    def read_temp_sublist_txt(self, txtlist):
        tf = open(txtlist,'r')
        subjects = tf.readlines()
        tf.close()
        subjects = [el.strip('\n') for el in subjects]
        subjects = [el.strip(' ') for el in subjects]
        for sub in subjects:
            print(sub)
        print(f'{len(subjects)} subjects in temporary list.')
        self.temp_subs = subjects

    # Create new directory (don't overwrite existing directories)
    def create_dirs(self, studydir):
        cmd = [None]
        if os.path.exists(studydir):
            new_studydir = f'{studydir}+'
            print(f'Directory {studydir} already exists.\nMaking new directory, {studydir}+ ...\n')
            cmd[0] = f'mkdir {new_studydir}'
            self.exec_cmds(cmd)
            self.studydir = new_studydir
        else:
            print(f'Creating {studydir} ...\n')
            cmd[0] = f'mkdir {studydir}'
            self.exec_cmds(cmd)
            self.studydir = studydir
        
    # Copy files into subdirs in new directory tree and rename them
    def cp_and_rename_files(self, files_list: List[str], session_num, subjectID, studydir):
        cmd=[None]*2
        for f in files_list:
            filename_ls = f.split('/')
            fn = f'{filename_ls[-1]}' # fn w extension
            fn_ls = str.split('.')
            f = fn_ls[0] # fn without ext
            if f in fn:
                ext = str.replace(f,'') # get fn extension
            if 'REST' in f: # rest files
                fn_new = f'Rest_S{session_num}_R1_E1{ext}'
                dest = f'{studydir}/{subjectID}/func/unprocessed/rest/session_{session_num}/run_1'
            else: # field maps or other files
                fn_new = f'S{session_num}_{fn}'
                dest = f'{studydir}/{subjectID}/func/unprocessed/field_maps'
            cmd[0] = f'cp {f} {dest}' # copy files to studydir dir
            cmd[1] = f'mv {dest}/{fn} {dest}/{fn_new}' # rename files
            self.exec_cmds(cmd)

    