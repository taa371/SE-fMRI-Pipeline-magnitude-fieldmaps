# Liston Multi-echo fMRI Pipeline File Prep

# Holland Brown

# Updated 2023-07-18
# Created 2023-05-02

# Structure file directories and copy raw fMRI files into new dir tree in preparation for the Liston lab's ME fMRI Pipeline

# Sources
    # Liston ME Pipeline (written by Chuck Lynch) >> https://github.com/cjl2007/Liston-Laboratory-MultiEchofMRI-Pipeline

#--------------------------------------------------------------------------------------------
# %%
def exec_cmds(commands): # run commands in system terminal (must be bash terminal, and function input must be list)
    for command in commands:
        subprocess.run(command, shell=True, executable='/bin/bash') # run command in bash shell


import glob
import os
import subprocess
from my_imaging_tools import fmri_tools

# origin = '/Volumes/LACIE-SHARE/EVO_raw_data_bkup/WCM_raw_MRI_data'
# destination = '/Volumes/LACIE-SHARE/EVO_MEP_data/WCM_MRI_data'

# origin = '/media/holland/LACIE-SHARE/EVO_multiecho_pipeline_data/UW_raw_MRI_data'
destination = '/media/holland/LACIE-SHARE/EVO_multiecho_pipeline_data/UW_fieldmaps'


# %% Create destination directory tree
p = fmri_tools(destination)
datadir = p.create_dirs(destination) # create new main data directory

# Create destination subject directories
subdestdirs = []
for sub in p.subs:
    subdir = p.create_dirs(f'{datadir}/{sub}')
    subdestdirs.append(subdir)

# Create subject dir trees (based on ExampleDataOrganization on MEP GitHub)
for destdir in subdestdirs:
    # anat dir tree
    a = p.create_dirs(f'{destdir}/anat')
    a1 = p.create_dirs(f'{a}/unprocessed')
    a1_1 = p.create_dirs(f'{a1}/T1w')

    # func dir tree
    func = p.create_dirs(f'{destdir}/func')
    f = p.create_dirs(f'{func}/unprocessed')
    f1 = p.create_dirs(f'{f}/field_maps')
    f2 = p.create_dirs(f'{f}/rest')
    f2_1 = p.create_dirs(f'{f2}/session_1')
    f2_1_1 = p.create_dirs(f'{f2_1}/run_1')
    f2_2 = p.create_dirs(f'{f2}/session_2')
    f2_2_1 = p.create_dirs(f'{f2_2}/run_1')


# %% Copy raw anatomical files into destination subj dirs
subdirs = glob.glob(f'{destination}/*') # get subject list, 'subs'
subs = []
for s in subdirs:
    subID = s.split('/')
    sub = subID[-1]
    subs.append(sub)


cmd = [None]*2
for sub in subs:
    anat_dir = f'/Volumes/LACIE-SHARE/EVO_fsl_analysis_data/{sub}_1/anat/anat.nii.gz' 
    filename_ls = anat_dir.split('/')
    fn = filename_ls[-1]
    cmd[0] = f'cp {anat_dir} {destination}/{sub}/anat' # copy files
    cmd[1] = f'mv {destination}/{sub}/anat/{fn} {destination}/{sub}/anat/T1w_1.nii.gz' # rename files
    exec_cmds(cmd)

    anat_dir = f'/Volumes/LACIE-SHARE/EVO_fsl_analysis_data/{sub}_2/anat/anat.nii.gz' 
    filename_ls = anat_dir.split('/')
    fn = filename_ls[-1]
    cmd[0] = f'cp {anat_dir} {destination}/{sub}/anat' # copy files
    cmd[1] = f'mv {destination}/{sub}/anat/{fn} {destination}/{sub}/anat/T1w_2.nii.gz' # rename files
    exec_cmds(cmd)

# %% Copy and rename functional files
# NOTE: MEP requires JSON files in addition to the NIFTIs for field maps and rest func data (not for anat, tho)
subdirs = glob.glob(f'{destination}/*') # get subject list, 'subs'
subs = []
for s in subdirs:
    subID = s.split('/')
    sub = subID[-1]
    subs.append(sub)
    print(sub)
print(len(subs))

cmd = [None]*2
for sub in subs:
    raw_files_1 = glob.glob(f'{origin}/{sub}_1/*Axial*.nii.gz') + glob.glob(f'{origin}/{sub}_1/*Axial*.json') + glob.glob(f'{origin}/{sub}_1/*DIFF*nii.gz') + glob.glob(f'{origin}/{sub}_1/*DIFF*.json') + glob.glob(f'{origin}/{sub}_1/*REST*.json')
    raw_files_2 = glob.glob(f'{origin}/{sub}_2/*Axial*.nii.gz') + glob.glob(f'{origin}/{sub}_2/*Axial*.json') + glob.glob(f'{origin}/{sub}_2/*DIFF*nii.gz') + glob.glob(f'{origin}/{sub}_2/*DIFF*.json') + glob.glob(f'{origin}/{sub}_2/*REST*.json')

    # raw_files_1 = glob.glob(f'{origin}/{sub}_1/*REST*.json') + glob.glob(f'{origin}/{sub}_1/*field_map*.json') + glob.glob(f'{origin}/{sub}_1/*fieldmap*.json')
    # raw_files_2 = glob.glob(f'{origin}/{sub}_2/*field_map*.json') + glob.glob(f'{origin}/{sub}_2/*fieldmap*.json') + glob.glob(f'{origin}/{sub}_2/*REST*.json')
    
    p.cp_and_rename_func(raw_files_1, '1', f'{sub}') # NOTE: session number must be a string value
    p.cp_and_rename_func(raw_files_2, '2', f'{sub}')


# %% Rename field maps 
datadir = destination
subdirs = glob.glob(f'{datadir}/*') # get subject list, 'subs'
subs = []
for s in subdirs:
    subID = s.split('/')
    sub = subID[-1]
    subs.append(sub)
# subs = ['97022']

cmd = [None]
for sub in subs: # phase, session 1
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    phaseFMs = glob.glob(f'{fm_dir}/S1*ph.nii.gz') # list of subject's phase fieldmap files
    for phaseFM_fn in phaseFMs:
        phaseFM_fn_ls = phaseFM_fn.split('/')
        ph_fn = phaseFM_fn_ls[-1]
        ph_fn_new = 'S1_FM_phase.nii.gz'
        cmd[0] = f'mv {phaseFM_fn} {fm_dir}/{ph_fn_new}'
        exec_cmds(cmd)

cmd = [None]
for sub in subs: # phase, session 2
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    phaseFMs = glob.glob(f'{fm_dir}/S2*ph.nii.gz') # list of subject's phase fieldmap files
    for phaseFM_fn in phaseFMs:
        phaseFM_fn_ls = phaseFM_fn.split('/')
        ph_fn = phaseFM_fn_ls[-1]
        ph_fn_new = 'S2_FM_phase.nii.gz'
        cmd[0] = f'mv {phaseFM_fn} {fm_dir}/{ph_fn_new}'
        exec_cmds(cmd)

cmd = [None]
for sub in subs: # double-echo, session 1
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    echoFMs = glob.glob(f'{fm_dir}/S1*e1.nii.gz') + glob.glob(f'{fm_dir}/S1*e2.nii.gz') # list of subject's double-echo fieldmap files
    for echoFM_fn in echoFMs:
        echoFM_fn_ls = echoFM_fn.split('/')
        echo_fn = echoFM_fn_ls[-1]
        echo_fn_suffix = echo_fn.split('_')
        suffix = echo_fn_suffix[-1]
        echo_fn_new = f'S1_FM_magnitude_{suffix}'
        cmd[0] = f'mv {echoFM_fn} {fm_dir}/{echo_fn_new}'
        exec_cmds(cmd)

cmd = [None]
for sub in subs: # double-echo, session 2
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    echoFMs = glob.glob(f'{fm_dir}/S2*e1.nii.gz') + glob.glob(f'{fm_dir}/S2*e2.nii.gz') # list of subject's double-echo fieldmap files
    for echoFM_fn in echoFMs:
        echoFM_fn_ls = echoFM_fn.split('/')
        echo_fn = echoFM_fn_ls[-1]
        echo_fn_suffix = echo_fn.split('_')
        suffix = echo_fn_suffix[-1]
        echo_fn_new = f'S2_FM_magnitude_{suffix}'
        cmd[0] = f'mv {echoFM_fn} {fm_dir}/{echo_fn_new}'
        exec_cmds(cmd)

# %% rename FM JSONs
datadir = destination
subdirs = glob.glob(f'{datadir}/*') # get subject list, 'subs'
subs = []
for s in subdirs:
    subID = s.split('/')
    sub = subID[-1]
    subs.append(sub)
# subs = ['97022']

cmd = [None]
for sub in subs: # phase, session 1
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    phaseFMs = glob.glob(f'{fm_dir}/S1*ph.json') # list of subject's phase fieldmap files
    for phaseFM_fn in phaseFMs:
        phaseFM_fn_ls = phaseFM_fn.split('/')
        ph_fn = phaseFM_fn_ls[-1]
        ph_fn_new = 'S1_FM_phase.json'
        cmd[0] = f'mv {phaseFM_fn} {fm_dir}/{ph_fn_new}'
        exec_cmds(cmd)

cmd = [None]
for sub in subs: # phase, session 2
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    phaseFMs = glob.glob(f'{fm_dir}/S2*ph.json') # list of subject's phase fieldmap files
    for phaseFM_fn in phaseFMs:
        phaseFM_fn_ls = phaseFM_fn.split('/')
        ph_fn = phaseFM_fn_ls[-1]
        ph_fn_new = 'S2_FM_phase.json'
        cmd[0] = f'mv {phaseFM_fn} {fm_dir}/{ph_fn_new}'
        exec_cmds(cmd)

cmd = [None]
for sub in subs: # double-echo, session 1
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    echoFMs = glob.glob(f'{fm_dir}/S1*e1.json') + glob.glob(f'{fm_dir}/S1*e2.json') # list of subject's double-echo fieldmap files
    for echoFM_fn in echoFMs:
        echoFM_fn_ls = echoFM_fn.split('/')
        echo_fn = echoFM_fn_ls[-1]
        echo_fn_suffix = echo_fn.split('_')
        suffix = echo_fn_suffix[-1]
        echo_fn_new = f'S1_FM_magnitude_{suffix}'
        cmd[0] = f'mv {echoFM_fn} {fm_dir}/{echo_fn_new}'
        exec_cmds(cmd)

cmd = [None]
for sub in subs: # double-echo, session 2
    fm_dir = f'{datadir}/{sub}/func/unprocessed/field_maps'
    echoFMs = glob.glob(f'{fm_dir}/S2*e1.json') + glob.glob(f'{fm_dir}/S2*e2.json') # list of subject's double-echo fieldmap files
    for echoFM_fn in echoFMs:
        echoFM_fn_ls = echoFM_fn.split('/')
        echo_fn = echoFM_fn_ls[-1]
        echo_fn_suffix = echo_fn.split('_')
        suffix = echo_fn_suffix[-1]
        echo_fn_new = f'S2_FM_magnitude_{suffix}'
        cmd[0] = f'mv {echoFM_fn} {fm_dir}/{echo_fn_new}'
        exec_cmds(cmd)
# %% Remove files (if necessary)
filename2rm = '*DIFF*' # file name glob should search for
cmd = [None]
for sub in subs:
    subj_dir = f'{destination}/{sub}/func/unprocessed/field_maps'
    files2rm = glob.glob(f'{subj_dir}/{filename2rm}') # removing dti field maps
    for file in files2rm:
        cmd[0] = f'rm {file}'
        print(f'Removing {file}...')
        exec_cmds(cmd)
# %%
