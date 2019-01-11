/* Copyright (c) 2018, EPFL/Blue Brain Project
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
 *
 * This file is part of the circuit explorer for Brayns
 * <https://github.com/favreau/Brayns-UC-CircuitExplorer>
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3.0 as published
 * by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef LOG_H
#define LOG_H

#include <iostream>

#define PLUGIN_ERROR std::cerr << "[ERROR] [FRACTALS] "
#define PLUGIN_WARN std::cerr << "[WARN ] [FRACTALS] "
#define PLUGIN_INFO std::cout << "[INFO ] [FRACTALS] "
#ifdef NDEBUG
#define PLUGIN_DEBUG \
    if (false)       \
    std::cout
#else
#define PLUGIN_DEBUG std::cout << "[DEBUG] [FRACTALS] "
#endif

#define PLUGIN_THROW(exc)                        \
    {                                            \
        PLUGIN_ERROR << exc.what() << std::endl; \
        throw exc;                               \
    }

#endif // LOG_H
