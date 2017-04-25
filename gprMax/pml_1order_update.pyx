# Copyright (C) 2015-2017: The University of Edinburgh
#                 Authors: Craig Warren and Antonis Giannopoulos
#
# This file is part of gprMax.
#
# gprMax is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# gprMax is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with gprMax.  If not, see <http://www.gnu.org/licenses/>.

import numpy as np
cimport numpy as np
from cython.parallel import prange

from gprMax.constants cimport floattype_t
from gprMax.constants cimport complextype_t


############################################
# Electric field PML updates - xminus slab #
############################################
cpdef void update_pml_1order_electric_xminus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsE,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] EPhi1,
                    floattype_t[:, :, :, ::1] EPhi2,
                    floattype_t[:, ::1] ERA,
                    floattype_t[:, ::1] ERB,
                    floattype_t[:, ::1] ERE,
                    floattype_t[:, ::1] ERF,
                    float d
            ):
    """This function updates the Ey and Ez field components for the xminus slab.

        Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, ERA, ERB, ERE, ERF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEy, materialEz
    cdef float dx, dHy, dHz, RA0, RB0, RE0, RF0
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        RA0 = (ERA[0, i] - 1)
        RB0 = ERB[0, i]
        RE0 = ERE[0, i]
        RF0 = ERF[0, i]
        ii = xf - i
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii - 1, jj, kk]) / dx
                Ey[ii, jj, kk] = Ey[ii, jj, kk] - updatecoeffsE[materialEy, 4] * (RA0 * dHz + RB0 * EPhi1[0, i, j, k])
                EPhi1[0, i, j, k] = RE0 * EPhi1[0, i, j, k] - RF0 * dHz
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii - 1, jj, kk]) / dx
                Ez[ii, jj, kk] = Ez[ii, jj, kk] + updatecoeffsE[materialEz, 4] * (RA0 * dHy + RB0 * EPhi2[0, i, j, k])
                EPhi2[0, i, j, k] = RE0 * EPhi2[0, i, j, k] - RF0 * dHy


###########################################
# Electric field PML updates - xplus slab #
###########################################
cpdef void update_pml_1order_electric_xplus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsE,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] EPhi1,
                    floattype_t[:, :, :, ::1] EPhi2,
                    floattype_t[:, ::1] ERA,
                    floattype_t[:, ::1] ERB,
                    floattype_t[:, ::1] ERE,
                    floattype_t[:, ::1] ERF,
                    float d
            ):
    """This function updates the Ey and Ez field components for the xplus slab.

    Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, ERA, ERB, ERE, ERF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEy, materialEz
    cdef float dx, dHy, dHz, RA0, RB0, RE0, RF0
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        RA0 = (ERA[0, i] - 1)
        RB0 = ERB[0, i]
        RE0 = ERE[0, i]
        RF0 = ERF[0, i]
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii - 1, jj, kk]) / dx
                Ey[ii, jj, kk] = Ey[ii, jj, kk] - updatecoeffsE[materialEy, 4] * (RA0 * dHz + RB0 * EPhi1[0, i, j, k])
                EPhi1[0, i, j, k] = RE0 * EPhi1[0, i, j, k] - RF0 * dHz
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii - 1, jj, kk]) / dx
                Ez[ii, jj, kk] = Ez[ii, jj, kk] + updatecoeffsE[materialEz, 4] * (RA0 * dHy + RB0 * EPhi2[0, i, j, k])
                EPhi2[0, i, j, k] = RE0 * EPhi2[0, i, j, k] - RF0 * dHy


############################################
# Electric field PML updates - yminus slab #
############################################
cpdef void update_pml_1order_electric_yminus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsE,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] EPhi1,
                    floattype_t[:, :, :, ::1] EPhi2,
                    floattype_t[:, ::1] ERA,
                    floattype_t[:, ::1] ERB,
                    floattype_t[:, ::1] ERE,
                    floattype_t[:, ::1] ERF,
                    float d
            ):
    """This function updates the Ex and Ez field components for the yminus slab.

    Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, ERA, ERB, ERE, ERF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEz
    cdef float dy, dHx, dHz, RA0, RB0, RE0, RF0
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = yf - j
            RA0 = (ERA[0, j] - 1)
            RB0 = ERB[0, j]
            RE0 = ERE[0, j]
            RF0 = ERF[0, j]
            for k in range(0, nz):
                kk = k + zs
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii, jj - 1, kk]) / dy
                Ex[ii, jj, kk] = Ex[ii, jj, kk] + updatecoeffsE[materialEx, 4] * (RA0 * dHz + RB0 * EPhi1[0, i, j, k])
                EPhi1[0, i, j, k] = RE0 * EPhi1[0, i, j, k] - RF0 * dHz
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj - 1, kk]) / dy
                Ez[ii, jj, kk] = Ez[ii, jj, kk] - updatecoeffsE[materialEz, 4] * (RA0 * dHx + RB0 * EPhi2[0, i, j, k])
                EPhi2[0, i, j, k] = RE0 * EPhi2[0, i, j, k] - RF0 * dHx


###########################################
# Electric field PML updates - yplus slab #
###########################################
cpdef void update_pml_1order_electric_yplus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsE,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] EPhi1,
                    floattype_t[:, :, :, ::1] EPhi2,
                    floattype_t[:, ::1] ERA,
                    floattype_t[:, ::1] ERB,
                    floattype_t[:, ::1] ERE,
                    floattype_t[:, ::1] ERF,
                    float d
            ):
    """This function updates the Ex and Ez field components for the yplus slab.

    Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, ERA, ERB, ERE, ERF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEz
    cdef float dy, dHx, dHz, RA0, RB0, RE0, RF0
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            RA0 = (ERA[0, j] - 1)
            RB0 = ERB[0, j]
            RE0 = ERE[0, j]
            RF0 = ERF[0, j]
            for k in range(0, nz):
                kk = k + zs
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii, jj - 1, kk]) / dy
                Ex[ii, jj, kk] = Ex[ii, jj, kk] + updatecoeffsE[materialEx, 4] * (RA0 * dHz + RB0 * EPhi1[0, i, j, k])
                EPhi1[0, i, j, k] = RE0 * EPhi1[0, i, j, k] - RF0 * dHz
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj - 1, kk]) / dy
                Ez[ii, jj, kk] = Ez[ii, jj, kk] - updatecoeffsE[materialEz, 4] * (RA0 * dHx + RB0 * EPhi2[0, i, j, k])
                EPhi2[0, i, j, k] = RE0 * EPhi2[0, i, j, k] - RF0 * dHx


############################################
# Electric field PML updates - zminus slab #
############################################
cpdef void update_pml_1order_electric_zminus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsE,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] EPhi1,
                    floattype_t[:, :, :, ::1] EPhi2,
                    floattype_t[:, ::1] ERA,
                    floattype_t[:, ::1] ERB,
                    floattype_t[:, ::1] ERE,
                    floattype_t[:, ::1] ERF,
                    float d
            ):
    """This function updates the Ex and Ey field components for the zminus slab.

        Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, ERA, ERB, ERE, ERF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
        """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEy
    cdef float dz, dHx, dHy, RA0, RB0, RE0, RF0
    dz = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = zf - k
                RA0 = (ERA[0, k] - 1)
                RB0 = ERB[0, k]
                RE0 = ERE[0, k]
                RF0 = ERF[0, k]
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii, jj, kk - 1]) / dz
                Ex[ii, jj, kk] = Ex[ii, jj, kk] - updatecoeffsE[materialEx, 4] * (RA0 * dHy + RB0 * EPhi1[0, i, j, k])
                EPhi1[0, i, j, k] = RE0 * EPhi1[0, i, j, k] - RF0 * dHy
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj, kk - 1]) / dz
                Ey[ii, jj, kk] = Ey[ii, jj, kk] + updatecoeffsE[materialEy, 4] * (RA0 * dHx + RB0 * EPhi2[0, i, j, k])
                EPhi2[0, i, j, k] = RE0 * EPhi2[0, i, j, k] - RF0 * dHx


###########################################
# Electric field PML updates - zplus slab #
###########################################
cpdef void update_pml_1order_electric_zplus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsE,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] EPhi1,
                    floattype_t[:, :, :, ::1] EPhi2,
                    floattype_t[:, ::1] ERA,
                    floattype_t[:, ::1] ERB,
                    floattype_t[:, ::1] ERE,
                    floattype_t[:, ::1] ERF,
                    float d
            ):
    """This function updates the Ex and Ey field components for the zplus slab.

    Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, ERA, ERB, ERE, ERF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEy
    cdef float dz, dHx, dHy, RA0, RB0, RE0, RF0
    dz = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                RA0 = (ERA[0, k] - 1)
                RB0 = ERB[0, k]
                RE0 = ERE[0, k]
                RF0 = ERF[0, k]
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii, jj, kk - 1]) / dz
                Ex[ii, jj, kk] = Ex[ii, jj, kk] - updatecoeffsE[materialEx, 4] * (RA0 * dHy + RB0 * EPhi1[0, i, j, k])
                EPhi1[0, i, j, k] = RE0 * EPhi1[0, i, j, k] - RF0 * dHy
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj, kk - 1]) / dz
                Ey[ii, jj, kk] = Ey[ii, jj, kk] + updatecoeffsE[materialEy, 4] * (RA0 * dHx + RB0 * EPhi2[0, i, j, k])
                EPhi2[0, i, j, k] = RE0 * EPhi2[0, i, j, k] - RF0 * dHx


############################################
# Magnetic field PML updates - xminus slab #
############################################
cpdef void update_pml_1order_magnetic_xminus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsH,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] HPhi1,
                    floattype_t[:, :, :, ::1] HPhi2,
                    floattype_t[:, ::1] HRA,
                    floattype_t[:, ::1] HRB,
                    floattype_t[:, ::1] HRE,
                    floattype_t[:, ::1] HRF,
                    float d
            ):
    """This function updates the Hy and Hz field components for the xminus slab.

    Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, HRA, HRB, ERE, HRF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHy, materialHz
    cdef float dx, dEy, dEz, RA0, RB0, RE0, RF0
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = xf - (i + 1)
        RA0 = (HRA[0, i] - 1)
        RB0 = HRB[0, i]
        RE0 = HRE[0, i]
        RF0 = HRF[0, i]
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEz = (Ez[ii + 1, jj, kk] - Ez[ii, jj, kk]) / dx
                Hy[ii, jj, kk] = Hy[ii, jj, kk] + updatecoeffsH[materialHy, 4] * (RA0 * dEz + RB0 * HPhi1[0, i, j, k])
                HPhi1[0, i, j, k] = RE0 * HPhi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEy = (Ey[ii + 1, jj, kk] - Ey[ii, jj, kk]) / dx
                Hz[ii, jj, kk] = Hz[ii, jj, kk] - updatecoeffsH[materialHz, 4] * (RA0 * dEy + RB0 * HPhi2[0, i, j, k])
                HPhi2[0, i, j, k] = RE0 * HPhi2[0, i, j, k] - RF0 * dEy


###########################################
# Magnetic field PML updates - xplus slab #
###########################################
cpdef void update_pml_1order_magnetic_xplus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsH,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] HPhi1,
                    floattype_t[:, :, :, ::1] HPhi2,
                    floattype_t[:, ::1] HRA,
                    floattype_t[:, ::1] HRB,
                    floattype_t[:, ::1] HRE,
                    floattype_t[:, ::1] HRF,
                    float d
            ):
    """This function updates the Hy and Hz field components for the xplus slab.

    Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, HRA, HRB, HRE, HRF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHy, materialHz
    cdef float dx, dEy, dEz, RA0, RB0, RE0, RF0
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        RA0 = (HRA[0, i] - 1)
        RB0 = HRB[0, i]
        RE0 = HRE[0, i]
        RF0 = HRF[0, i]
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEz = (Ez[ii + 1, jj, kk] - Ez[ii, jj, kk]) / dx
                Hy[ii, jj, kk] = Hy[ii, jj, kk] + updatecoeffsH[materialHy, 4] * (RA0 * dEz + RB0 * HPhi1[0, i, j, k])
                HPhi1[0, i, j, k] = RE0 * HPhi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEy = (Ey[ii + 1, jj, kk] - Ey[ii, jj, kk]) / dx
                Hz[ii, jj, kk] = Hz[ii, jj, kk] - updatecoeffsH[materialHz, 4] * (RA0 * dEy + RB0 * HPhi2[0, i, j, k])
                HPhi2[0, i, j, k] = RE0 * HPhi2[0, i, j, k] - RF0 * dEy


############################################
# Magnetic field PML updates - yminus slab #
############################################
cpdef void update_pml_1order_magnetic_yminus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsH,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] HPhi1,
                    floattype_t[:, :, :, ::1] HPhi2,
                    floattype_t[:, ::1] HRA,
                    floattype_t[:, ::1] HRB,
                    floattype_t[:, ::1] HRE,
                    floattype_t[:, ::1] HRF,
                    float d
            ):
    """This function updates the Hx and Hz field components for the yminus slab.

    Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, HRA, HRB, HRE, HRF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHz
    cdef float dy, dEx, dEz, RA0, RB0, RE0, RF0
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = yf - (j + 1)
            RA0 = (HRA[0, j] - 1)
            RB0 = HRB[0, j]
            RE0 = HRE[0, j]
            RF0 = HRF[0, j]
            for k in range(0, nz):
                kk = k + zs
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEz = (Ez[ii, jj + 1, kk] - Ez[ii, jj, kk]) / dy
                Hx[ii, jj, kk] = Hx[ii, jj, kk] - updatecoeffsH[materialHx, 4] * (RA0 * dEz + RB0 * HPhi1[0, i, j, k])
                HPhi1[0, i, j, k] = RE0 * HPhi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEx = (Ex[ii, jj + 1, kk] - Ex[ii, jj, kk]) / dy
                Hz[ii, jj, kk] = Hz[ii, jj, kk] + updatecoeffsH[materialHz, 4] * (RA0 * dEx + RB0 * HPhi2[0, i, j, k])
                HPhi2[0, i, j, k] = RE0 * HPhi2[0, i, j, k] - RF0 * dEx


###########################################
# Magnetic field PML updates - yplus slab #
###########################################
cpdef void update_pml_1order_magnetic_yplus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsH,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] HPhi1,
                    floattype_t[:, :, :, ::1] HPhi2,
                    floattype_t[:, ::1] HRA,
                    floattype_t[:, ::1] HRB,
                    floattype_t[:, ::1] HRE,
                    floattype_t[:, ::1] HRF,
                    float d
            ):
    """This function updates the Hx and Hz field components for the yplus slab.

    Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, HRA, HRB, HRE, HRF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHz
    cdef float dy, dEx, dEz, RA0, RB0, RE0, RF0
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            RA0 = (HRA[0, j] - 1)
            RB0 = HRB[0, j]
            RE0 = HRE[0, j]
            RF0 = HRF[0, j]
            for k in range(0, nz):
                kk = k + zs
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEz = (Ez[ii, jj + 1, kk] - Ez[ii, jj, kk]) / dy
                Hx[ii, jj, kk] = Hx[ii, jj, kk] - updatecoeffsH[materialHx, 4] * (RA0 * dEz + RB0 * HPhi1[0, i, j, k])
                HPhi1[0, i, j, k] = RE0 * HPhi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEx = (Ex[ii, jj + 1, kk] - Ex[ii, jj, kk]) / dy
                Hz[ii, jj, kk] = Hz[ii, jj, kk] + updatecoeffsH[materialHz, 4] * (RA0 * dEx + RB0 * HPhi2[0, i, j, k])
                HPhi2[0, i, j, k] = RE0 * HPhi2[0, i, j, k] - RF0 * dEx


############################################
# Magnetic field PML updates - zminus slab #
############################################
cpdef void update_pml_1order_magnetic_zminus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsH,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] HPhi1,
                    floattype_t[:, :, :, ::1] HPhi2,
                    floattype_t[:, ::1] HRA,
                    floattype_t[:, ::1] HRB,
                    floattype_t[:, ::1] HRE,
                    floattype_t[:, ::1] HRF,
                    float d
            ):
    """This function updates the Hx and Hy field components for the zminus slab.

    Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, HRA, HRB, HRE, HRF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHy
    cdef float dz, dEx, dEy, RA0, RB0, RE0, RF0
    dz = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = zf - (k + 1)
                RA0 = (HRA[0, k] - 1)
                RB0 = HRB[0, k]
                RE0 = HRE[0, k]
                RF0 = HRF[0, k]
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEy = (Ey[ii, jj, kk + 1] - Ey[ii, jj, kk]) / dz
                Hx[ii, jj, kk] = Hx[ii, jj, kk] + updatecoeffsH[materialHx, 4] * (RA0 * dEy + RB0 * HPhi1[0, i, j, k])
                HPhi1[0, i, j, k] = RE0 * HPhi1[0, i, j, k] - RF0 * dEy
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEx = (Ex[ii, jj, kk + 1] - Ex[ii, jj, kk]) / dz
                Hy[ii, jj, kk] = Hy[ii, jj, kk] - updatecoeffsH[materialHy, 4] * (RA0 * dEx + RB0 * HPhi2[0, i, j, k])
                HPhi2[0, i, j, k] = RE0 * HPhi2[0, i, j, k] - RF0 * dEx


###########################################
# Magnetic field PML updates - zplus slab #
###########################################
cpdef void update_pml_1order_magnetic_zplus(
                    int xs,
                    int xf,
                    int ys,
                    int yf,
                    int zs,
                    int zf,
                    int nthreads,
                    floattype_t[:, ::1] updatecoeffsH,
                    np.uint32_t[:, :, :, ::1] ID,
                    floattype_t[:, :, ::1] Ex,
                    floattype_t[:, :, ::1] Ey,
                    floattype_t[:, :, ::1] Ez,
                    floattype_t[:, :, ::1] Hx,
                    floattype_t[:, :, ::1] Hy,
                    floattype_t[:, :, ::1] Hz,
                    floattype_t[:, :, :, ::1] HPhi1,
                    floattype_t[:, :, :, ::1] HPhi2,
                    floattype_t[:, ::1] HRA,
                    floattype_t[:, ::1] HRB,
                    floattype_t[:, ::1] HRE,
                    floattype_t[:, ::1] HRF,
                    float d
            ):
    """This function updates the Hx and Hy field components for the zplus slab.

    Args:
        xs, xf, ys, yf, zs, zf (int): Cell coordinates of entire box
        nthreads (int): Number of threads to use
        updatecoeffs, ID, E, H (memoryviews): Access to update coeffients, ID and field component arrays
        EPhi, HPhi, HRA, HRB, HRE, HRF (memoryviews): Access to PML coefficient arrays
        d (float): Spatial discretisation, e.g. dx, dy or dz
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHy
    cdef float dz, dEx, dEy, RA0, RB0, RE0, RF0
    dz = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                RA0 = (HRA[0, k] - 1)
                RB0 = HRB[0, k]
                RE0 = HRE[0, k]
                RF0 = HRF[0, k]
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEy = (Ey[ii, jj, kk + 1] - Ey[ii, jj, kk]) / dz
                Hx[ii, jj, kk] = Hx[ii, jj, kk] + updatecoeffsH[materialHx, 4] * (RA0 * dEy + RB0 * HPhi1[0, i, j, k])
                HPhi1[0, i, j, k] = RE0 * HPhi1[0, i, j, k] - RF0 * dEy
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEx = (Ex[ii, jj, kk + 1] - Ex[ii, jj, kk]) / dz
                Hy[ii, jj, kk] = Hy[ii, jj, kk] - updatecoeffsH[materialHy, 4] * (RA0 * dEx + RB0 * HPhi2[0, i, j, k])
                HPhi2[0, i, j, k] = RE0 * HPhi2[0, i, j, k] - RF0 * dEx
