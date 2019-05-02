#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 15 08:11:28 2018

@author: mfromano
"""

# Hua-an Tseng, huaantseng@gmail.com
# inspirited by https://github.com/kr-hansen/ptmc

import collections
import h5py
from nd2reader import ND2Reader
import numpy as np
import os
import PIL
from scipy import ndimage
from scipy import signal
import sys
import tifffile
import tkinter as tk
from tkinter import filedialog
from tqdm import tqdm
#from tqdm import tqdm_notebook as tqdm

def motion_correction(filename_list=None, save_filename=None, save_foldername='motion_corrected', as_group = True, save_format='tif', **kwargs):
    if filename_list is None:
        root = tk.Tk()
        root.withdraw()
        filename_list = tk.filedialog.askopenfilenames()
        filename_list = list(filename_list)

    if len(filename_list)==1:
        print("\033[1;32;40mProcessing %s\033[0m" % filename_list[0])
    else:
        current_foldername = os.path.dirname(filename_list[0])
        print("\033[1;32;40mProcessing files in %s\033[0m" % current_foldername)

    for filename in tqdm(filename_list, desc='Files'):
        [_, file_extension] = os.path.splitext(filename)
        if file_extension=='.tif':
            images = load_tif_tifffile(filename)
        elif file_extension=='.nd2':
            images = ND2Reader(filename)
        else:
            print("Incorrect file format.")
            break

        if as_group:
            try:
                [image_shift, _] = calculate_shift(images, ref_image=ref_image, **kwargs)
            except:
                [image_shift, ref_image] = calculate_shift(images, **kwargs)
        else:
            [image_shift, _] = calculate_shift(images, **kwargs)

        shifted_images = apply_shift(images, image_shift)

        current_foldername = os.path.dirname(filename)

        if save_filename is None:
            current_filename = os.path.basename(filename)
            current_save_filename = '/hdd2/test'+'/'+save_foldername+'/m_'+current_filename
        else:
            current_save_filename = '/hdd2/test'+'/'+save_foldername+'/'+save_filename

        [current_save_filename, _] = os.path.splitext(current_save_filename)
        current_save_filename = current_save_filename+'.'+save_format

        if os.path.isdir(current_foldername + '/' + save_foldername) is False:
            os.makedirs(current_foldername + '/' + save_foldername)

        if save_format=='npy':
            np.save(current_save_filename, shifted_images, allow_pickle=False)
        elif save_format == 'hdf5':
            opened_save_file = h5py.File(current_save_filename, "w")
            opened_save_file.create_dataset('image_data', data=shifted_images, chunks=True);
            opened_save_file.close()
        else:
            save_tif_pil(shifted_images, current_save_filename)
            

def apply_fft_highpass_flt(images, sigma=50):
    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)
        squeeze_image = True
    else:
        squeeze_image = False
    images = images.astype('float')
    # print("Applying sharpen....")
    for frame_idx, image in enumerate(images):
        fft_image = np.fft.fft2(image)
        fft_image = ndimage.fourier_gaussian(fft_image, sigma)
        fft_image = np.fft.ifft2(fft_image)
        images[frame_idx, :, :] = image - fft_image.real
    if squeeze_image:
        images = np.squeeze(images)
    return images


def apply_highpass_flt(images, sigma=50):
    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)
        squeeze_image = True
    else:
        squeeze_image = False
    images = images.astype('float')
    # print("Applying sharpen....")
    for frame_idx, image in enumerate(images):
        lowpass_image = ndimage.gaussian_filter(image, sigma)
        images[frame_idx, :, :] = image - lowpass_image
    if squeeze_image:
        images = np.squeeze(images)
    return images


def apply_hist_eq(images):
    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)
        squeeze_image = True
    else:
        squeeze_image = False
    image_shape = images.shape[1:]
    # print("Applying histogram equalization....")
    for frame_idx, image in enumerate(images):
        dist, bins = np.histogram(image.flatten(), 2 ** 16, density=True)
        cum_dist = dist.cumsum()
        cum_dist = 2 ** 16 * cum_dist / [cum_dist[-1]]
        image = np.interp(image.flatten(), bins[:-1], cum_dist)
        images[frame_idx, :, :] = image.reshape(image_shape)
    if squeeze_image:
        images = np.squeeze(images)
    return images


def apply_homo_flt(images, sigma=7):
    # https://github.com/kr-hansen/ptmc
    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)
        squeeze_image = True
    else:
        squeeze_image = False
    images = images.astype('float')
    # print("Applying sharpen....")
    for frame_idx, image in enumerate(images):
        log_image = np.log1p((image - image.min()) / (image.max() - image.min()))
        filter_log_image = ndimage.gaussian_filter(log_image, sigma)
        log_image = log_image - filter_log_image
        log_image = log_image - log_image.min()
        images[frame_idx, :, :] = (np.expm1(log_image) * (image.max() - image.min())) + image.min()
    if squeeze_image:
        images = np.squeeze(images)
    return images


def apply_log_fft_highpass_flt(images, sigma=50):
    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)
        squeeze_image = True
    else:
        squeeze_image = False
    images = images.astype('float')
    # print("Applying sharpen....")
    for frame_idx, image in enumerate(images):
        log_image = np.log1p((image - image.min()) / (image.max() - image.min()))
        fft_image = np.fft.fft2(log_image)
        fft_image = ndimage.fourier_gaussian(fft_image, sigma)
        fft_image = np.fft.ifft2(fft_image)
        log_image = log_image - fft_image.real
        images[frame_idx, :, :] = (np.expm1(log_image) * (image.max() - image.min())) + image.min()
    if squeeze_image:
        images = np.squeeze(images)
    return images


def apply_median_flt(images, sigma=3):
    # http://www.scipy-lectures.org/advanced/image_processing/
    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)
        squeeze_image = True
    else:
        squeeze_image = False
    images = images.astype('float')
    # print("Applying sharpen....")
    for frame_idx, image in enumerate(images):
        images[frame_idx, :, :] = ndimage.median_filter(image, sigma)
    if squeeze_image:
        images = np.squeeze(images)
    return images


def apply_sharpen(images, sigma=[2, 1], alpha=100):
    # http://www.scipy-lectures.org/advanced/image_processing/
    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)
        squeeze_image = True
    else:
        squeeze_image = False
    images = images.astype('float')
    # print("Applying sharpen....")
    for frame_idx, image in enumerate(images):
        lowpass_image = ndimage.gaussian_filter(image, sigma[0])
        filter_lowpass_image = ndimage.gaussian_filter(lowpass_image, sigma[1])
        images[frame_idx, :, :] = lowpass_image + alpha * (lowpass_image - filter_lowpass_image)
    if squeeze_image:
        images = np.squeeze(images)
    return images


def apply_shift(images, image_shift):
    if len(images) != len(image_shift):
        raise IndexError("images and image_shift require the same length in first dimension.")
    else:
        # print("Applying shift....")
        try:
            shifted_images = np.zeros(images.shape, dtype=images.dtype)  # images as numpy array
        except:
            shifted_images = np.zeros((len(images), images[0].shape[0], images[0].shape[1]), dtype='uint16')  # images as nd2

        for frame_idx, image in enumerate(tqdm(images, desc="Applying shift", leave=False)):
            if np.array_equal(image_shift[frame_idx], [0, 0]):
                shifted_images[frame_idx, :, :] = image
            else:
                shifted_images[frame_idx, :, :] = ndimage.shift(image, image_shift[frame_idx])

        return shifted_images


def apply_std_eq(images):
    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)
        squeeze_image = True
    else:
        squeeze_image = False
    image_shape = images.shape[1:]
    # print("Applying histogram equalization....")
    for frame_idx, image in enumerate(images):
        images[frame_idx, :, :] = (image - image.mean()) / image.std()
    if squeeze_image:
        images = np.squeeze(images)
    return images


def calculate_shift(images, ref_image=None, local_subpixel=[1, 0], global_subpixel=1,
                    process_functions=['apply_highpass_flt', 'apply_sharpen', 'apply_std_eq']):
    # images is numpy array frame x height x width
    # global_subpixel: don't use it
    # local_subpixel: most of time, it's not better

    process_function_list = {
        'apply_fft_highpass_flt': apply_fft_highpass_flt,
        'apply_highpass_flt': apply_highpass_flt,
        'apply_hist_eq': apply_hist_eq,
        'apply_homo_flt': apply_homo_flt,
        'apply_log_fft_highpass_flt': apply_log_fft_highpass_flt,
        'apply_median_flt': apply_median_flt,
        'apply_sharpen': apply_sharpen,
        'apply_std_eq': apply_std_eq,
        'remove_edges': remove_edges,
        'remove_low_intensity': remove_low_intensity,
    }

    images = np.array(images)

    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)

    if ref_image is None:
        ref_image = np.mean(images, axis=0)
    elif ref_image=='first':
        ref_image = images[0]

    print("Image size: %sx%s, frame numeber: %s" % (images.shape[1], images.shape[2], images.shape[0]))
    print("Process functions (%s): %s" % (len(process_functions), ', '.join(map(str, process_functions))))

    image_shift = np.zeros((len(images), 2))

    if process_functions is not None:
        for process_function_name in process_functions:
            current_process_function = process_function_list[process_function_name]
            ref_image = current_process_function(ref_image)

    if global_subpixel < 1:
        ref_image = ndimage.zoom(ref_image, (1 / subpixel, 1 / subpixel), order=1)

    ref_image_center = np.array(ref_image.shape) // 2
    ref_image_fft = np.fft.fft2(ref_image)

    # print("Calculating shift....")
    for frame_idx, image in enumerate(tqdm(images, desc="Calculating shift", leave=False)):

        if process_functions is not None:
            for process_function_name in process_functions:
                current_process_function = process_function_list[process_function_name]
                image = current_process_function(image)

        if global_subpixel < 1:
            image = ndimage.zoom(image, (1 / subpixel, 1 / subpixel), order=1)

        image_fft = np.fft.fft2(image)
        cross_correlation = abs(np.fft.ifft2(image_fft * ref_image_fft.conjugate()))
        cross_correlation_peak = np.array(
            np.unravel_index(np.argmax(np.fft.fftshift(cross_correlation)), ref_image.shape))
        image_shift[frame_idx, :] = -1 * (cross_correlation_peak - ref_image_center)

        if local_subpixel[0] < 1 and local_subpixel[1] > 0:
            local_pixel_range = 5
            refined_cross_correlation_peak = cross_correlation_peak
            refined_ref_image_center = ref_image_center
            refined_ref_image = ref_image
            refined_image = image
            try:
                for zoom_in_idx in range(local_subpixel[1]):
                    refined_scale = zoom_in_idx + 1
                    refined_ref_image_slice = np.s_[
                                              refined_ref_image_center[0] - local_pixel_range:refined_ref_image_center[
                                                                                                  0] + local_pixel_range,
                                              refined_ref_image_center[1] - local_pixel_range:refined_ref_image_center[
                                                                                                  1] + local_pixel_range]
                    refined_image_slice = np.s_[refined_cross_correlation_peak[0] - local_pixel_range:
                    refined_cross_correlation_peak[0] + local_pixel_range,
                                          refined_cross_correlation_peak[1] - local_pixel_range:
                                          refined_cross_correlation_peak[1] + local_pixel_range]
                    refined_ref_image = ndimage.zoom(refined_ref_image[refined_ref_image_slice],
                                                     (1 / local_subpixel[0], 1 / local_subpixel[0]), order=1)
                    refined_image = ndimage.zoom(refined_image[refined_image_slice],
                                                 (1 / local_subpixel[0], 1 / local_subpixel[0]), order=1)

                    refined_ref_image_center = np.array(refined_ref_image.shape) // 2

                    refined_ref_image_fft = np.fft.fft2(refined_ref_image)
                    refined_image_fft = np.fft.fft2(refined_image)
                    refined_cross_correlation = abs(np.fft.ifft2(refined_image_fft * refined_ref_image_fft.conjugate()))
                    refined_cross_correlation_peak = np.array(
                        np.unravel_index(np.argmax(np.fft.fftshift(refined_cross_correlation)),
                                         refined_ref_image.shape))
                    image_shift[frame_idx, :] += -1 * (refined_cross_correlation_peak - refined_ref_image_center) * (
                    local_subpixel[0] ** refined_scale)
            except:
                pass
    if global_subpixel < 1:
        image_shift = image_shift * global_subpixel

    return image_shift, ref_image


def load_tif_tifffile(filename_list):
    # load all frames
    # fast for frame number >1000
    # check load_tif_pil(filename_list, start_frame, frame_number)
    if isinstance(filename_list, str):
        filename_list = [filename_list]
    output_images = collections.deque([])
    # print("Loading files....")
    for filename in filename_list:
        with tifffile.TiffFile(filename) as image_data:
            temp_images = image_data.asarray()
            output_images.append(temp_images)
    output_images = np.dstack(output_images)
    return output_images  # frame x height x width

def remove_low_intensity(images, std_threshold=2):
    # remove any pixel with intensity below mean+(std_threshold*std)
    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)
        squeeze_image = True
    else:
        squeeze_image = False
    images = images.astype('float')
    for frame_idx, image in enumerate(images):
        image[image<(np.mean(image)+std_threshold*np.std(image))] = 0
        images[frame_idx, :, :] = image
    if squeeze_image:
        images = np.squeeze(images)
    return images


def remove_edges(images, edges=0.1):
    # remove any pixel at the edges: UDLR
    if images.ndim == 2:
        images = np.expand_dims(images, axis=0)
        squeeze_image = True
    else:
        squeeze_image = False
    images = images.astype('float')

    edges = np.array(edges)
    if edges.size == 1:
        edges = np.repeat(edges, 4)

    if any(edges < 1):
        u_pixel = int(np.floor(images.shape[1] * edges[0]))
        d_pixel = int(np.floor(images.shape[1] * edges[1]))
        l_pixel = int(np.floor(images.shape[2] * edges[2]))
        r_pixel = int(np.floor(images.shape[2] * edges[3]))
    else:
        u_pixel = int(np.floor(edges[0]))
        d_pixel = int(np.floor(edges[1]))
        l_pixel = int(np.floor(edges[2]))
        r_pixel = int(np.floor(edges[3]))
    # print("Cropping edges: U%s D%s L%s R%s" % (u_pixel,d_pixel,l_pixel,r_pixel))

    images = images[:, u_pixel + 1:-1 * d_pixel - 1, l_pixel + 1:-1 * r_pixel - 1]

    if squeeze_image:
        images = np.squeeze(images)
    return images

def save_tif_pil(images, save_filename):
    if images.ndim == 2:
        print('Only 2 dimensions, saving single image')
        images = PIL.Image.fromarray(images)
        images.save(save_filename, save_all=True)
    else:
        saved_image = []
        for image in images:
            saved_image.append(PIL.Image.fromarray(image))

        saved_image[0].save(save_filename, save_all=True, append_images=saved_image[1:])

if __name__ == '__main__':
    motion_correction()