#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Apr  2 10:31:21 2018

@author: mfromano
"""

# run hua-an's motion correction

import motion_correction
import scipy.io as sio
import numpy as np

fi = sio.loadmat('/fastdata/ca-imaging-ed/metadata_suffix_new.mat')
fi = fi['metaout']


for i in np.arange(1,10):
    if fi[0][i]:
        currfiles = [a[0] for a in fi[0][i][1][0]]
        suffix = fi[0][i][0][0]
        foutnames = [['m2_' + suffix + '_' + str(x) + '.tif'] for x in range(len(currfiles))]
        motion_correction.motion_correction(filename_list=currfiles[0:4])




for i in np.arange(10,18):
    if fi[0][i]:
       currfiles = [a[0] for a in fi[0][i][1][0]]  
       suffix = fi[0][i][0][0]
       foutnames = [['m2_' + suffix + '_' + str(x) + '.tif'] for x in range(len(currfiles))]
       motion_correction.motion_correction(filename_list=currfiles[0:4])
    
for i in np.arange(18,len(fi[0])):
    if fi[0][i]:
        currfiles = [a[0] for a in fi[0][i][1][0]]  
        suffix = fi[0][i][0][0]
        foutnames = [['m2_' + suffix + '_' + str(x) + '.tif'] for x in range(len(currfiles))]
        motion_correction.motion_correction(filename_list=currfiles[0:4])