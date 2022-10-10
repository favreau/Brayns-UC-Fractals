/* Copyright (c) 2018-2019, EPFL/Blue Brain Project
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
 *
 * This file is part of the circuit explorer for Brayns
 * <https://github.com/favreau/Brayns-UC-Fractals>
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

#include "FractalsPlugin.h"
#include "../common/commonTypes.h"
#include "../common/log.h"

#include <brayns/common/ActionInterface.h>
#include <brayns/common/PropertyMap.h>
#include <brayns/engineapi/Engine.h>
#include <brayns/parameters/ParametersManager.h>
#include <brayns/pluginapi/Plugin.h>

template <typename EnumT>
inline std::vector<std::pair<std::string, FractalType>> enumMap()
{
    return {{"Julia", FractalType::julia},
            {"Mandelbrot", FractalType::mandelbrot},
            {"Mandelbulb", FractalType::mandelbulb}};
}

template <typename EnumT>
inline std::vector<std::string> enumNames()
{
    std::vector<std::string> v;
    for (const auto &p : enumMap<EnumT>())
        v.push_back(p.first);
    return v;
}

void _addFractalsRenderer(brayns::Engine &engine)
{
    PLUGIN_INFO << "Registering Fractals renderer" << std::endl;

    brayns::PropertyMap properties;
    properties.setProperty({"param1", -0.7, -10., 10., {"Parameter 1"}});
    properties.setProperty({"param2", 0.27015, -10., 10., {"Parameter 2"}});
    properties.setProperty({"shadows", 0., 0., 1., {"Shadow intensity"}});
    properties.setProperty({"softShadows", 0., 0., 1., {"Shadow softness"}});
    properties.setProperty({"minShadingThreshold",
                            0.01,
                            0.01,
                            1.,
                            {"Transparency min threshold"}});
    properties.setProperty(
        {"maxShadingThreshold", 1., 0.01, 1., {"Transparency max threshold"}});
    properties.setProperty({"maxIterations",
                            32,
                            1,
                            255,
                            {"Maximum number of compute iterations"}});
    properties.setProperty(
        {"volumeSamplesPerRay", 32, 1, 1024, {"Samples per ray"}});
    properties.setProperty({"fractalType",
                            int32_t(FractalType::julia),
                            enumNames<FractalType>(),
                            {"Type of fractal"}});
    properties.setProperty({"exposure", 1., 0.01, 10., {"Exposure"}});

    engine.addRendererType("fractals", properties);
}

void _addMengerSpongeRenderer(brayns::Engine &engine)
{
    PLUGIN_INFO << "Registering Menger Sponge renderer" << std::endl;

    // clang-format off
    brayns::PropertyMap properties;
    properties.setProperty(
        {"aoDistance", 10000., {"Ambient occlusion distance"}});
    properties.setProperty(
        {"aoWeight", 0., 0., 1., {"Ambient occlusion weight"}});
    properties.setProperty({"shadows", 0., 0., 1., {"Shadow intensity"}});
    properties.setProperty({"softShadows", 0., 0., 1., {"Shadow softness"}});
    properties.setProperty({"farPlane", 10., 0., 100., {"Far plane"}});
    properties.setProperty({"mapIterations", 4, 1, 10, {"Map iterations"}});
    engine.addRendererType("mengersponge", properties);
}

FractalsPlugin::FractalsPlugin()
    : ExtensionPlugin()
{
}

void FractalsPlugin::init()
{
    _addFractalsRenderer(_api->getEngine());
    _addMengerSpongeRenderer(_api->getEngine());
    _api->getParametersManager().getRenderingParameters().setCurrentRenderer("fractals");
}

extern "C" brayns::ExtensionPlugin *brayns_plugin_create(int /*argc*/,
                                                         char ** /*argv*/)
{
    PLUGIN_INFO << "Initializing fractals plugin" << std::endl;
    return new FractalsPlugin();
}
