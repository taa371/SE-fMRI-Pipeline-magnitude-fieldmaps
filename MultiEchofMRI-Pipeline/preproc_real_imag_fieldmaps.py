# Preprocess Philips fieldmaps stored as "real" and "imaginary" files
# Holland Brown
# Updated 2023-07-30
# Created 2023-07-30

# %%
import glob
import os
from my_imaging_tools import fmri_tools

studydir=f'/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data'
t = fmri_tools(studydir) # automatically generates subject list from dirs in studydir, stored in t.subs

# %% Cleaning up fieldmap dirs
subs = ['W004'] # test
cmd = [None]*2
for sub in subs:
    func_dir = f'{studydir}/{sub}/func/unprocessed'
    raw_fieldmaps = glob.glob(f'{func_dir}/field_maps/*_AxialField_Mapping_*')
    for raw_fm in raw_fieldmaps:
        cmd[0] = f'cp {raw_fm} {func_dir}'
        t.exec_cmds([cmd[0]])
    cmd[0] = f'rm -r {func_dir}/field_maps'
    cmd[1] = f'mkdir {func_dir}/field_maps'
    t.exec_cmds(cmd)
    raw_fieldmaps2 = glob.glob(f'{func_dir}/*_AxialField_Mapping_*')
    for raw_fm in raw_fieldmaps2:
        cmd[0] = f'mv {raw_fm} {func_dir}/field_maps'
        t.exec_cmds([cmd[0]])

# %% Step 1: merge the real field maps from the different echoes