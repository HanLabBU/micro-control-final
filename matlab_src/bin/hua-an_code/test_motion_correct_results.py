#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 15 08:02:43 2018

@author: mfromano
"""

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Apr  2 10:31:21 2018

@author: mfromano
"""

# run hua-an's motion correction

import motion_correction2
import scipy.io as sio
import numpy as np

fi = sio.loadmat('/fastdata/ca-imaging-ed/metadata_raw_gcamp.mat')
fi = fi['metaout']


for i in np.arange(0,1):
    if fi[0][i]:
        currfiles = [a[0] for a in fi[0][i][1][0]]
        suffix = fi[0][i][0][0]
        motion_correction2.motion_correction(filename_list=currfiles[0:4])

