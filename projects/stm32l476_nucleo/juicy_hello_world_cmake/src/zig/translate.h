
/** @copyright Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the "Software"), to deal in the Software without restriction, including without
 * limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * @author    Sazerac4 (lm-embeddedsystems@laposte.net)
 * @date      08-2025
 */
/**
 *  @file translate_c.h
 *  @brief
 *  @pre
 *  @details
 */

#ifndef __TRANSLATE_H__
#define __TRANSLATE_H__

#ifdef __cplusplus
extern "C"
{
#endif


// WORKAROUND: to fix zig translate-c with unknow wint_t type
typedef int wint_t; // NOLINT(readability-identifier-naming)

/*********************
 *      INCLUDES
 *********************/
#include "cmake_config.h"
#include "cmake_version.h"

#include <stdint.h>

/*********************
 *      DEFINES
 *********************/

/**********************
 *     TYPEDEFS
 **********************/

/**********************
 *  GLOBAL MACROS
 **********************/

/**********************
 *  GLOBAL VARIABLES
 **********************/

/**********************
 *  GLOBAL PROTOTYPES
 **********************/

/**********************
 *   ERROR ASSERT
 **********************/

#ifdef __cplusplus
}
#endif

#endif /* __TRANSLATE_H__ */
