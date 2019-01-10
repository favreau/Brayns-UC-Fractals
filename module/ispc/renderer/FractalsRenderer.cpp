/* Copyright (c) 2018, Cyrille Favreau
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
 *
 * This file is part of the reseach Brayns module
 * <https://github.com/favreau/Brayns-Research-Modules>
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

#include "FractalsRenderer.h"

// ospray
#include <ospray/SDK/common/Data.h>
#include <ospray/SDK/lights/Light.h>

// ispc exports
#include "FractalsRenderer_ispc.h"

using namespace ospray;

namespace brayns
{
void FractalsRenderer::commit()
{
    Renderer::commit();

    _lightData = (ospray::Data*)getParamData("lights");
    _lightArray.clear();

    if (_lightData)
        for (size_t i = 0; i < _lightData->size(); ++i)
            _lightArray.push_back(
                ((ospray::Light**)_lightData->data)[i]->getIE());

    _lightPtr = _lightArray.empty() ? nullptr : &_lightArray[0];

    _bgColor = getParam3f("bgColor", ospray::vec3f(0.f));
    _shadows = getParam1f("shadows", 0.f);
    _softShadows = getParam1f("softShadows", 0.f);
    _minShadingThreshold = getParam1f("minShadingThreshold", 0.f);
    _maxShadingThreshold = getParam1f("maxShadingThreshold", 1.f);
    _randomNumber = getParam1i("randomNumber", 0);
    _param1 = getParam1f("param1", 0.f);
    _param2 = getParam1f("param2", 0.f);
    _maxIterations = getParam1i("maxIterations", 0);
    _fractalType = static_cast<FractalType>(getParam1i("fractalType", 0));

    // Transfer function
    _transferFunctionDiffuseData = getParamData("transferFunctionDiffuseData");
    _transferFunctionEmissionData =
        getParamData("transferFunctionEmissionData");
    _transferFunctionSize = getParam1i("transferFunctionSize", 255);
    _transferFunctionMinValue = getParam1f("transferFunctionMinValue", 0.f);
    _transferFunctionRange = getParam1f("transferFunctionRange", 255.f);

    // Volume
    _volumeSamplesPerRay = getParam1i("volumeSamplesPerRay", 64);

    ispc::FractalsRenderer_set(
        getIE(), (ispc::vec3f&)_bgColor, (ispc::FractalType&)_fractalType,
        _shadows, _softShadows, _minShadingThreshold, _maxShadingThreshold,
        _maxIterations, _randomNumber, _param1, _param2, _lightPtr,
        _lightArray.size(), _volumeSamplesPerRay,
        _transferFunctionDiffuseData
            ? (ispc::vec4f*)_transferFunctionDiffuseData->data
            : NULL,
        _transferFunctionEmissionData
            ? (ispc::vec3f*)_transferFunctionEmissionData->data
            : NULL,
        _transferFunctionSize, _transferFunctionMinValue,
        _transferFunctionRange);
}

FractalsRenderer::FractalsRenderer()
{
    ispcEquivalent = ispc::FractalsRenderer_create(this);
}

OSP_REGISTER_RENDERER(FractalsRenderer, fractals);
} // namespace brayns
